#!/usr/bin/env python3

import json
import psycopg2
import time
from app import get_database_schema, get_database_schema_json, get_db_connection, clear_schema_cache, schema_cache

def test_database_connection():
    """Test database connection"""
    print("Testing database connection...")
    try:
        conn = get_db_connection()
        if conn:
            print("✅ Database connection successful!")
            conn.close()
            return True
        else:
            print("❌ Database connection failed!")
            return False
    except Exception as e:
        print(f"❌ Database connection error: {e}")
        return False

def test_schema_fetching():
    """Test schema fetching functionality"""
    print("\nTesting schema fetching...")
    try:
        schema = get_database_schema()
        if schema:
            print("✅ Schema fetching successful!")
            print(f"Schema preview (first 500 chars):\n{schema[:500]}...")
            return True
        else:
            print("❌ Schema fetching failed!")
            return False
    except Exception as e:
        print(f"❌ Schema fetching error: {e}")
        return False

def test_schema_json():
    """Test JSON schema fetching"""
    print("\nTesting JSON schema fetching...")
    try:
        schema_json = get_database_schema_json()
        if schema_json:
            print("✅ JSON schema fetching successful!")
            print(f"Found {len(schema_json)} tables:")
            for table_name in schema_json.keys():
                print(f"  - {table_name} ({len(schema_json[table_name])} columns)")
            return True
        else:
            print("❌ JSON schema fetching failed!")
            return False
    except Exception as e:
        print(f"❌ JSON schema fetching error: {e}")
        return False

def test_caching():
    """Test schema caching functionality"""
    print("\nTesting schema caching...")
    try:
        # Clear cache first
        clear_schema_cache()
        print("  Cache cleared")
        
        # First call - should fetch from database
        start_time = time.time()
        schema1 = get_database_schema()
        first_call_time = time.time() - start_time
        
        if not schema1:
            print("❌ First schema fetch failed!")
            return False
            
        print(f"  First call (from DB): {first_call_time:.3f}s")
        
        # Second call - should use cache
        start_time = time.time()
        schema2 = get_database_schema()
        second_call_time = time.time() - start_time
        
        print(f"  Second call (from cache): {second_call_time:.3f}s")
        
        # Verify both schemas are identical
        if schema1 == schema2:
            print("  ✅ Cached schema matches original")
        else:
            print("  ❌ Cached schema doesn't match original")
            return False
        
        # Test force refresh
        schema3 = get_database_schema(force_refresh=True)
        if schema3 == schema1:
            print("  ✅ Force refresh works correctly")
        else:
            print("  ❌ Force refresh returned different schema")
            return False
        
        # Check cache info
        cache_age = time.time() - schema_cache['timestamp']
        print(f"  Cache age: {cache_age:.1f} seconds")
        print(f"  Cache has data: {schema_cache['text'] is not None}")
        
        print("✅ Schema caching test passed!")
        return True
        
    except Exception as e:
        print(f"❌ Schema caching test error: {e}")
        return False

def main():
    """Run all tests"""
    print("=== Database Schema Integration with Caching Test ===\n")
    
    # Test 1: Database Connection
    db_test = test_database_connection()
    
    # Test 2: Schema Fetching (only if DB connection works)
    if db_test:
        schema_test = test_schema_fetching()
        json_test = test_schema_json()
        cache_test = test_caching()
        
        print("\n=== Test Summary ===")
        print(f"Database Connection: {'✅ PASS' if db_test else '❌ FAIL'}")
        print(f"Schema Fetching: {'✅ PASS' if schema_test else '❌ FAIL'}")
        print(f"JSON Schema: {'✅ PASS' if json_test else '❌ FAIL'}")
        print(f"Schema Caching: {'✅ PASS' if cache_test else '❌ FAIL'}")
        
        if db_test and schema_test and json_test and cache_test:
            print("\n🎉 All tests passed! The schema integration with caching is working correctly.")
        else:
            print("\n⚠️  Some tests failed. Please check your database configuration.")
    else:
        print("\n⚠️  Database connection failed. Please check your secrets.json file.")
        print("\nMake sure your secrets.json contains:")
        print('{\n  "api_key": "your_gemini_api_key",\n  "database": {\n    "host": "your_host",\n    "database": "your_database",\n    "user": "your_username",\n    "password": "your_password",\n    "port": 5432\n  }\n}')

if __name__ == "__main__":
    main() 