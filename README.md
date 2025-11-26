# SQL Query Generator with Gemini API

This is a Flask application that uses Google's Gemini API to generate SQL queries from natural language prompts. The application provides a simple web interface where users can input their requirements in natural language and get the corresponding SQL query.

## Features

- Natural language to SQL query conversion
- Clean and responsive web interface
- Real-time query generation
- Error handling and validation
- Health check endpoint

## Prerequisites

- Python 3.7 or higher
- Google Gemini API key
- PostgreSQL database (optional, for query execution)

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd <repository-directory>
```

2. Install the required dependencies:
```bash
pip install -r requirements.txt
```

3. Configure the API key and database credentials:
   - Copy `secrets.json.example` to `secrets.json`
   - Update `secrets.json` with your actual Gemini API key and PostgreSQL database credentials

## Running the Application

1. Start the Flask server:
```bash
python app.py
```

2. Open your web browser and navigate to:
```
http://localhost:5000
```

## Usage

1. (Optional) Upload a SQL schema file (.sql) to provide context for your database structure
2. Enter your natural language prompt in the text area
3. Choose one of the following options:
   - **Generate SQL**: Only generate the SQL query
   - **Generate & Execute**: Generate the SQL query and execute it against your database
4. The generated SQL query will appear below the input area
5. If executed, query results will be displayed in a table below the query
6. Download results as CSV or Excel files using the download buttons

Example prompts:
- "Find all employees in the sales department who joined after 2020"
- "Calculate the average salary by department"
- "List all customers who made purchases above $1000"
- "Show me all orders with their customer details from the last 30 days"
- "Find products that are out of stock"

### Query Execution Features

- **Execute Query**: Run the generated SQL query against your PostgreSQL database
- **Results Table**: View query results in a formatted table
- **Download Options**: Export results as CSV or Excel files
- **Row Count**: See the number of rows returned by the query

### Schema Upload Feature

The application now supports uploading SQL schema files to generate more accurate queries:

- Upload a `.sql` file containing your database schema (CREATE TABLE statements)
- The AI will use the exact table and column names from your schema
- Queries will be generated to match your specific database structure
- A sample schema file (`sample_schema.sql`) is included for testing

## API Endpoints

- `GET /`: Main web interface
- `POST /generate-sql`: Generate SQL query from prompt and optional schema
  - Request body: `{"prompt": "your natural language prompt", "schema": "optional SQL schema", "execute": false}`
  - Response: `{"status": "success", "sql_query": "generated SQL query"}`
- `POST /execute-query`: Execute a SQL query against the database
  - Request body: `{"query": "SQL query to execute"}`
  - Response: `{"status": "success", "columns": [...], "data": [...], "row_count": n}`
- `POST /download/csv`: Download query results as CSV
  - Request body: `{"query": "SQL query to execute"}`
  - Response: CSV file download
- `POST /download/excel`: Download query results as Excel
  - Request body: `{"query": "SQL query to execute"}`
  - Response: Excel file download
- `GET /health`: Health check endpoint

## Error Handling

The application includes error handling for:
- Missing prompts
- Invalid API responses
- Server errors
- Network issues

## Contributing

Feel free to submit issues and enhancement requests! 
