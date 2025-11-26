from flask import Flask, request, jsonify, render_template, send_file
import google.generativeai as genai
import os
import json
import psycopg2
import pandas as pd
from io import BytesIO
import tempfile
from werkzeug.utils import secure_filename

with open('secrets.json', 'r') as file:
    secrets = json.load(file)
    api_key = secrets['api_key']
    db_config = secrets.get('database', {})

app = Flask(__name__)

# Configure Gemini API
# Replace 'your_api_key_here' with your actual Gemini API key
genai.configure(api_key=api_key)

# Initialize the model
model = genai.GenerativeModel('gemini-1.5-flash')

# No caching - always read fresh from files
# Global variable to store uploaded schema
uploaded_schema = {
    'text': None,
    'json': None,
    'filename': None
}

def get_db_connection():
    """
    Create a connection to the PostgreSQL database
    """
    try:
        connection = psycopg2.connect(
            host=db_config.get('host', 'localhost'),
            database=db_config.get('database', ''),
            user=db_config.get('user', ''),
            password=db_config.get('password', ''),
            port=db_config.get('port', 5432)
        )
        return connection
    except Exception as e:
        print(f"Database connection error: {e}")
        return None

# Cache functions removed - always read fresh data

def parse_sql_dump_schema():
    """Parse schema from SQL dump file instead of database"""
    try:
        sql_file_path = 'dump-investors-with-comments_new.sql'
        
        if not os.path.exists(sql_file_path):
            print(f"Warning: {sql_file_path} not found")
            return None, None
        
        print(f"Reading schema from SQL dump: {sql_file_path}")
        
        schema_dict = {}
        current_table = None
        in_create_table = False
        
        with open(sql_file_path, 'r', encoding='utf-8') as file:
            for line in file:
                line = line.strip()
                
                # Check for CREATE TABLE statement
                if line.startswith('CREATE TABLE'):
                    # Extract table name
                    table_match = line.split()
                    if len(table_match) >= 3:
                        table_name = table_match[2].replace('public.', '').replace('(', '')
                        current_table = table_name
                        schema_dict[current_table] = []
                        in_create_table = True
                        continue
                
                # Process column definitions
                if in_create_table and current_table:
                    # End of table definition
                    if line.startswith(');') or line == ')':
                        in_create_table = False
                        current_table = None
                        continue
                    
                    # Skip constraint lines and other non-column lines
                    if (line.startswith('CONSTRAINT') or 
                        line.startswith('PRIMARY KEY') or 
                        line.startswith('FOREIGN KEY') or
                        line.startswith('CHECK') or
                        line.startswith('UNIQUE') or
                        line.startswith('--') or
                        not line or
                        line.startswith('ALTER')):
                        continue
                    
                    # Parse column definition
                    if line and not line.startswith('--'):
                        # Clean line and check if it's a column definition
                        clean_line = line.rstrip(',').strip()
                        parts = clean_line.split()
                        
                        if len(parts) >= 2 and not parts[0].upper() in ['CONSTRAINT', 'PRIMARY', 'FOREIGN', 'UNIQUE', 'CHECK']:
                            column_name = parts[0].strip(',')
                            
                            # Handle data types with parameters (e.g., character varying(50))
                            data_type = parts[1]
                            if len(parts) > 2 and '(' in parts[1] and ')' not in parts[1]:
                                # Data type spans multiple tokens
                                i = 2
                                while i < len(parts) and ')' not in parts[i-1]:
                                    data_type += ' ' + parts[i]
                                    i += 1
                            
                            # Extract additional attributes
                            line_upper = line.upper()
                            is_nullable = 'NOT NULL' not in line_upper
                            
                            # Check for default values
                            default_value = None
                            if 'DEFAULT' in line_upper:
                                default_idx = line_upper.find('DEFAULT')
                                remaining = line[default_idx + 7:].strip()
                                if remaining:
                                    # Handle different default value formats
                                    if remaining.startswith("'"):
                                        # String default
                                        end_quote = remaining.find("'", 1)
                                        if end_quote > 0:
                                            default_value = remaining[:end_quote+1]
                                    else:
                                        # Numeric or function default
                                        default_value = remaining.split()[0] if remaining.split() else None
                                        if default_value:
                                            default_value = default_value.rstrip(',')
                            
                            # Check for key types
                            key_type = ''
                            if 'PRIMARY KEY' in line_upper:
                                key_type = 'PRIMARY KEY'
                            elif column_name.lower().endswith('_id') and column_name.lower() != 'id':
                                key_type = 'FOREIGN KEY'
                            elif column_name.lower() == 'id':
                                key_type = 'PRIMARY KEY'
                            
                            column_info = {
                                'column_name': column_name,
                                'data_type': data_type.strip(','),
                                'is_nullable': 'YES' if is_nullable else 'NO',
                                'column_default': default_value,
                                'key_type': key_type,
                                'check_constraint': ''
                            }
                            schema_dict[current_table].append(column_info)
        
        # Format schema as readable text
        schema_text = "DATABASE SCHEMA (from SQL dump):\n\n"
        for table_name, columns in schema_dict.items():
            schema_text += f"TABLE: {table_name}\n"
            schema_text += "-" * (len(table_name) + 7) + "\n"
            
            for col in columns:
                nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
                key_info = f" ({col['key_type']})" if col['key_type'] else ""
                
                schema_text += f"  {col['column_name']}: {col['data_type']} {nullable}{default}{key_info}\n"
            
            schema_text += "\n"
        
        # Create JSON format
        json_schema = {}
        for table_name, columns in schema_dict.items():
            json_schema[table_name] = []
            for col in columns:
                json_column = {
                    'column_name': col['column_name'],
                    'data_type': col['data_type'],
                    'is_nullable': col['is_nullable'] == 'YES',
                    'column_default': col['column_default'],
                    'key_type': col['key_type']
                }
                json_schema[table_name].append(json_column)
        
        print(f"Successfully parsed {len(schema_dict)} tables from SQL dump")
        return schema_text, json_schema
        
    except Exception as e:
        print(f"Error parsing SQL dump schema: {e}")
        return None, None

def fetch_fresh_schema():
    """Fetch fresh schema from SQL dump file (internal function)"""
    return parse_sql_dump_schema()

def get_database_schema(force_refresh=False):
    """
    Get database schema (prioritize uploaded schema, fallback to SQL dump file)
    """
    # Check if we have an uploaded schema
    if uploaded_schema['text']:
        print(f"Using uploaded schema from: {uploaded_schema['filename']}")
        return uploaded_schema['text']
    
    # Fallback to SQL dump file
    print("Loading fresh schema from SQL dump file...")
    schema_text, json_schema = fetch_fresh_schema()
    
    if schema_text:
        print("Schema loaded successfully from SQL dump file")
        return schema_text
    else:
        print("Failed to load schema from SQL dump file")
        return None

def get_database_schema_json(force_refresh=False):
    """
    Get database schema as JSON (prioritize uploaded schema, fallback to SQL dump file)
    """
    # Check if we have an uploaded schema
    if uploaded_schema['json']:
        print(f"Using uploaded JSON schema from: {uploaded_schema['filename']}")
        return uploaded_schema['json']
    
    # Fallback to SQL dump file
    print("Loading fresh schema from SQL dump for JSON...")
    schema_text, json_schema = fetch_fresh_schema()
    
    if json_schema:
        print("Schema JSON loaded successfully")
        return json_schema
    else:
        print("Failed to load schema from SQL dump file")
        return None

def execute_query(sql_query):
    """
    Execute SQL query and return results
    """
    try:
        connection = get_db_connection()
        if not connection:
            return {
                'status': 'error',
                'message': 'Failed to connect to database'
            }
        
        # Use pandas to execute query and get results
        df = pd.read_sql_query(sql_query, connection)
        connection.close()
        
        # Convert DataFrame to dictionary for JSON response
        results = {
            'status': 'success',
            'columns': df.columns.tolist(),
            'data': df.values.tolist(),
            'row_count': len(df)
        }
        
        return results
        
    except Exception as e:
        if 'connection' in locals():
            connection.close()
        return {
            'status': 'error',
            'message': str(e)
        }

def generate_sql_query(prompt, schema=None):
    """
    Generate SQL query using Gemini API based on the user's prompt and optional schema.
    """
    try:
        # Create a context-aware prompt for SQL generation with enhanced instructions
        system_prompt = """You are an expert SQL query generator for a financial lending platform database. Given a natural language prompt, generate the most appropriate SQL query.

IMPORTANT GUIDELINES:
1. Generate ONLY the SQL query without any explanations or markdown formatting
2. Use standard PostgreSQL syntax
3. Use the EXACT table and column names from the provided schema
4. Pay close attention to the detailed table definitions and column descriptions provided
5. Consider relationships between tables (user_id, user_source_group_id, etc.)
6. Use appropriate JOINs when data spans multiple tables
7. Apply proper filtering based on the business context described in the definitions
8. Consider date ranges, status filters, and business rules mentioned in the column descriptions
9. Use appropriate aggregations (COUNT, SUM, AVG) when asking for totals or statistics
10. Handle NULL values appropriately based on column descriptions
11. Use LIMIT when appropriate to avoid overwhelming results
12. Consider the business meaning behind the data (investments, loans, users, transactions, etc.)

BUSINESS CONTEXT UNDERSTANDING:
- This is a lending and investment platform database
- Users can be investors, borrowers, or channel partners
- Transactions include loans, investments, repayments, withdrawals
- Pay attention to status fields (ACTIVE, PENDING, SUCCESS, FAILED, etc.)
- Consider user source groups for segmentation
- Understand the difference between different transaction types and investment products
"""
        
        # Add schema information if provided
        if schema:
            system_prompt += f"""

{schema}

Based on the above detailed schema with table definitions and column descriptions, generate a SQL query for the following request:
"""
        else:
            system_prompt += """

User prompt: """
        
        # Combine system prompt with user input
        full_prompt = system_prompt + prompt
        
        # Generate response
        response = model.generate_content(full_prompt)
        
        # Extract the SQL query from the response
        sql_query = response.text.strip()
        
        # Clean up the response to remove any markdown formatting
        if sql_query.startswith('```sql'):
            sql_query = sql_query[6:]
        if sql_query.startswith('```'):
            sql_query = sql_query[3:]
        if sql_query.endswith('```'):
            sql_query = sql_query[:-3]
        
        sql_query = sql_query.strip()
        
        return {
            'status': 'success',
            'sql_query': sql_query
        }
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }

def parse_uploaded_sql_file(file_content):
    """
    Parse uploaded SQL file to extract schema information
    """
    try:
        schema_dict = {}
        current_table = None
        in_create_table = False
        
        lines = file_content.split('\n')
        for line in lines:
            line = line.strip()
            
            # Check for CREATE TABLE statement
            if line.upper().startswith('CREATE TABLE'):
                # Extract table name
                table_match = line.split()
                if len(table_match) >= 3:
                    table_name = table_match[2].replace('public.', '').replace('(', '').replace('`', '')
                    current_table = table_name
                    schema_dict[current_table] = []
                    in_create_table = True
                    continue
            
            # Process column definitions
            if in_create_table and current_table:
                # End of table definition
                if line.startswith(');') or line == ')':
                    in_create_table = False
                    current_table = None
                    continue
                
                # Skip constraint lines and other non-column lines
                if (line.upper().startswith('CONSTRAINT') or 
                    line.upper().startswith('PRIMARY KEY') or 
                    line.upper().startswith('FOREIGN KEY') or
                    line.upper().startswith('CHECK') or
                    line.upper().startswith('UNIQUE') or
                    line.startswith('--') or
                    not line or
                    line.upper().startswith('ALTER')):
                    continue
                
                # Parse column definition
                if line and not line.startswith('--'):
                    # Clean line and check if it's a column definition
                    clean_line = line.rstrip(',').strip()
                    parts = clean_line.split()
                    
                    if len(parts) >= 2 and not parts[0].upper() in ['CONSTRAINT', 'PRIMARY', 'FOREIGN', 'UNIQUE', 'CHECK']:
                        column_name = parts[0].strip(',').replace('`', '')
                        
                        # Handle data types with parameters
                        data_type = parts[1]
                        if len(parts) > 2 and '(' in parts[1] and ')' not in parts[1]:
                            # Data type spans multiple tokens
                            i = 2
                            while i < len(parts) and ')' not in parts[i-1]:
                                data_type += ' ' + parts[i]
                                i += 1
                        
                        # Extract additional attributes
                        line_upper = line.upper()
                        is_nullable = 'NOT NULL' not in line_upper
                        
                        # Check for default values
                        default_value = None
                        if 'DEFAULT' in line_upper:
                            default_idx = line_upper.find('DEFAULT')
                            remaining = line[default_idx + 7:].strip()
                            if remaining:
                                if remaining.startswith("'"):
                                    end_quote = remaining.find("'", 1)
                                    if end_quote > 0:
                                        default_value = remaining[:end_quote+1]
                                else:
                                    default_value = remaining.split()[0] if remaining.split() else None
                                    if default_value:
                                        default_value = default_value.rstrip(',')
                        
                        # Check for key types
                        key_type = ''
                        if 'PRIMARY KEY' in line_upper:
                            key_type = 'PRIMARY KEY'
                        elif column_name.lower().endswith('_id') and column_name.lower() != 'id':
                            key_type = 'FOREIGN KEY'
                        elif column_name.lower() == 'id':
                            key_type = 'PRIMARY KEY'
                        
                        column_info = {
                            'column_name': column_name,
                            'data_type': data_type.strip(','),
                            'is_nullable': 'YES' if is_nullable else 'NO',
                            'column_default': default_value,
                            'key_type': key_type,
                            'check_constraint': ''
                        }
                        schema_dict[current_table].append(column_info)
        
        # Format schema as readable text
        schema_text = "DATABASE SCHEMA (from uploaded SQL file):\n\n"
        for table_name, columns in schema_dict.items():
            schema_text += f"TABLE: {table_name}\n"
            schema_text += "-" * (len(table_name) + 7) + "\n"
            
            for col in columns:
                nullable = "NULL" if col['is_nullable'] == 'YES' else "NOT NULL"
                default = f" DEFAULT {col['column_default']}" if col['column_default'] else ""
                key_info = f" ({col['key_type']})" if col['key_type'] else ""
                
                schema_text += f"  {col['column_name']}: {col['data_type']} {nullable}{default}{key_info}\n"
            
            schema_text += "\n"
        
        # Create JSON format
        json_schema = {}
        for table_name, columns in schema_dict.items():
            json_schema[table_name] = []
            for col in columns:
                json_column = {
                    'column_name': col['column_name'],
                    'data_type': col['data_type'],
                    'is_nullable': col['is_nullable'] == 'YES',
                    'column_default': col['column_default'],
                    'key_type': col['key_type']
                }
                json_schema[table_name].append(json_column)
        
        return schema_text, json_schema, len(schema_dict)
        
    except Exception as e:
        print(f"Error parsing uploaded SQL file: {e}")
        return None, None, 0

@app.route('/upload-sql-file', methods=['POST'])
def upload_sql_file():
    """
    Handle SQL file upload and parse schema
    """
    try:
        if 'sql_file' not in request.files:
            return jsonify({
                'status': 'error',
                'message': 'No file provided'
            }), 400
        
        file = request.files['sql_file']
        if file.filename == '':
            return jsonify({
                'status': 'error',
                'message': 'No file selected'
            }), 400
        
        if file:
            filename = secure_filename(file.filename)
            
            # Read file content
            file_content = file.read().decode('utf-8')
            
            # Parse the SQL file
            schema_text, json_schema, tables_count = parse_uploaded_sql_file(file_content)
            
            if schema_text and json_schema:
                # Store in global variable
                uploaded_schema['text'] = schema_text
                uploaded_schema['json'] = json_schema
                uploaded_schema['filename'] = filename
                
                return jsonify({
                    'status': 'success',
                    'message': f'SQL file {filename} processed successfully',
                    'filename': filename,
                    'tables_parsed': tables_count
                }), 200
            else:
                return jsonify({
                    'status': 'error',
                    'message': 'Failed to parse SQL file. Please ensure it contains valid CREATE TABLE statements.'
                }), 400
                
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': f'Error processing file: {str(e)}'
        }), 500

@app.route('/get-uploaded-schema', methods=['GET'])
def get_uploaded_schema():
    """
    Get the uploaded schema information
    """
    try:
        if uploaded_schema['text']:
            return jsonify({
                'status': 'success',
                'schema': uploaded_schema['text'],
                'filename': uploaded_schema['filename'],
                'source': 'uploaded_file'
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'No uploaded schema available'
            }), 404
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/')
def index():
    """
    Serve the main page
    """
    return render_template('index.html')

@app.route('/generate-sql', methods=['POST'])
def generate_sql():
    """
    Endpoint to generate SQL query from user prompt with automatic schema detection
    """
    try:
        data = request.get_json()
        
        if not data or 'prompt' not in data:
            return jsonify({
                'status': 'error',
                'message': 'No prompt provided'
            }), 400
            
        prompt = data['prompt']
        execute_query_flag = data.get('execute', False)  # Whether to execute the query
        
        # Automatically fetch database schema
        schema = get_database_schema()
        if not schema:
            return jsonify({
                'status': 'error',
                'message': 'Failed to fetch database schema. Please check your database connection.'
            }), 500
        
        result = generate_sql_query(prompt, schema)
        
        if result['status'] == 'success' and execute_query_flag:
            # Execute the generated query
            query_result = execute_query(result['sql_query'])
            result['query_results'] = query_result
        
        if result['status'] == 'success':
            return jsonify(result), 200
        else:
            return jsonify(result), 500
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/execute-query', methods=['POST'])
def execute_sql_query():
    """
    Endpoint to execute a SQL query and return results
    """
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({
                'status': 'error',
                'message': 'No query provided'
            }), 400
            
        sql_query = data['query']
        result = execute_query(sql_query)
        
        return jsonify(result), 200 if result['status'] == 'success' else 500
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/download/<format>', methods=['POST'])
def download_results(format):
    """
    Download query results as CSV or Excel
    """
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({
                'status': 'error',
                'message': 'No query provided'
            }), 400
            
        sql_query = data['query']
        
        # Execute query to get fresh data
        connection = get_db_connection()
        if not connection:
            return jsonify({
                'status': 'error',
                'message': 'Failed to connect to database'
            }), 500
        
        df = pd.read_sql_query(sql_query, connection)
        connection.close()
        
        if format.lower() == 'csv':
            # Create CSV
            output = BytesIO()
            df.to_csv(output, index=False)
            output.seek(0)
            
            return send_file(
                output,
                mimetype='text/csv',
                as_attachment=True,
                download_name='query_results.csv'
            )
            
        elif format.lower() == 'excel':
            # Create Excel
            output = BytesIO()
            with pd.ExcelWriter(output, engine='openpyxl') as writer:
                df.to_excel(writer, sheet_name='Query Results', index=False)
            output.seek(0)
            
            return send_file(
                output,
                mimetype='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                as_attachment=True,
                download_name='query_results.xlsx'
            )
        else:
            return jsonify({
                'status': 'error',
                'message': 'Invalid format. Use csv or excel'
            }), 400
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/health', methods=['GET'])
def health_check():
    """
    Health check endpoint
    """
    try:
        # Check if SQL dump file exists
        sql_file_exists = os.path.exists('dump-investors-202506131512.sql')
        
        return jsonify({
            'status': 'healthy',
            'message': 'Service is running',
            'data_source': 'SQL schema files (dump or uploaded)',
            'sql_dump_file': 'available' if sql_file_exists else 'missing',
            'uploaded_schema': {
                'available': uploaded_schema['text'] is not None,
                'filename': uploaded_schema['filename'],
                'tables_count': len(uploaded_schema['json']) if uploaded_schema['json'] else 0
            },
            'files_checked': {
                'dump-investors-202506131512.sql': sql_file_exists
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'unhealthy',
            'error': str(e),
            'data_source': 'SQL schema files (dump or uploaded)'
        }), 503

@app.route('/get-schema', methods=['GET'])
def get_schema():
    """
    Endpoint to get database schema information
    """
    try:
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        schema = get_database_schema(force_refresh=force_refresh)
        
        if schema:
            return jsonify({
                'status': 'success',
                'schema': schema,
                'note': 'Schema loaded fresh from SQL dump file (no caching)'
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Failed to load schema from SQL dump file'
            }), 500
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/get-schema-json', methods=['GET'])
def get_schema_json():
    """
    Endpoint to get database schema as JSON structure
    """
    try:
        force_refresh = request.args.get('refresh', 'false').lower() == 'true'
        schema = get_database_schema_json(force_refresh=force_refresh)
        
        if schema:
            return jsonify({
                'status': 'success',
                'schema': schema,
                'note': 'Schema JSON loaded fresh from SQL dump file (no caching)'
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Failed to load schema from SQL dump file'
            }), 500
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/cache/status', methods=['GET'])
def get_cache_status():
    """
    Get data source status information (no caching)
    """
    try:
        sql_file_exists = os.path.exists('dump-investors-202506131512.sql')
        csv_file_exists = os.path.exists('INVESTOR_PUBLIC_DEFINATION_FILE.csv')
        
        return jsonify({
            'status': 'success',
            'cache_enabled': False,
            'data_source': 'Always fresh from files',
            'sql_dump_file': 'available' if sql_file_exists else 'missing',
            'csv_definitions_file': 'available' if csv_file_exists else 'missing',
            'note': 'No caching - data is always loaded fresh from files'
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/cache/clear', methods=['POST'])
def clear_cache():
    """
    Cache clear endpoint (no-op since there's no caching)
    """
    try:
        return jsonify({
            'status': 'success',
            'message': 'No cache to clear - data is always loaded fresh from files'
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/cache/refresh', methods=['POST'])
def refresh_cache():
    """
    Test loading fresh data from files (since there's no caching)
    """
    try:
        schema_text = get_database_schema()
        schema_json = get_database_schema_json()
        
        if schema_text and schema_json:
            return jsonify({
                'status': 'success',
                'message': 'Schema loaded successfully from files (no caching - always fresh)',
                'tables_loaded': len(schema_json) if schema_json else 0
            }), 200
        else:
            return jsonify({
                'status': 'error',
                'message': 'Failed to load schema from SQL dump file'
            }), 500
            
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

@app.route('/export-chart-data', methods=['POST'])
def export_chart_data():
    """
    Export query results in chart-friendly JSON format
    """
    try:
        data = request.get_json()
        
        if not data or 'query' not in data:
            return jsonify({
                'status': 'error',
                'message': 'No query provided'
            }), 400
            
        sql_query = data['query']
        chart_type = data.get('chart_type', 'bar')
        
        # Execute query to get results
        connection = get_db_connection()
        if not connection:
            return jsonify({
                'status': 'error',
                'message': 'Failed to connect to database'
            }), 500
        
        df = pd.read_sql_query(sql_query, connection)
        connection.close()
        
        if df.empty:
            return jsonify({
                'status': 'error',
                'message': 'Query returned no data'
            }), 400
        
        # Convert DataFrame to chart-friendly format
        columns = df.columns.tolist()
        data_rows = df.values.tolist()
        
        # Find numeric columns
        numeric_columns = []
        for i, col in enumerate(columns):
            if df[col].dtype in ['int64', 'float64', 'int32', 'float32']:
                numeric_columns.append({'index': i, 'name': col})
        
        chart_data = {
            'labels': [str(row[0]) for row in data_rows],  # First column as labels
            'datasets': []
        }
        
        # Create datasets for each numeric column (excluding first column if it's used as labels)
        start_index = 1 if len(columns) > 1 else 0
        colors = [
            'rgba(59, 130, 246, 0.6)',   # Blue
            'rgba(16, 185, 129, 0.6)',   # Green
            'rgba(245, 158, 11, 0.6)',   # Orange
            'rgba(239, 68, 68, 0.6)',    # Red
            'rgba(139, 92, 246, 0.6)',   # Purple
            'rgba(236, 72, 153, 0.6)',   # Pink
        ]
        
        for i in range(start_index, len(columns)):
            if any(num_col['index'] == i for num_col in numeric_columns):
                dataset = {
                    'label': columns[i],
                    'data': [float(row[i]) if row[i] is not None else 0 for row in data_rows],
                    'backgroundColor': colors[i % len(colors)],
                    'borderColor': colors[i % len(colors)].replace('0.6', '1'),
                    'borderWidth': 2
                }
                chart_data['datasets'].append(dataset)
        
        return jsonify({
            'status': 'success',
            'chart_data': chart_data,
            'chart_type': chart_type,
            'meta': {
                'total_rows': len(data_rows),
                'total_columns': len(columns),
                'numeric_columns': len(numeric_columns),
                'columns': columns
            }
        }), 200
        
    except Exception as e:
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000) 