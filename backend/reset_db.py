"""
Quick script to reset the database by deleting django_migrations table
and re-running migrations from scratch.
"""
import os
import sys
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from django.db import connection

# Delete the migrations table
with connection.cursor() as cursor:
    try:
        cursor.execute("DROP TABLE IF EXISTS django_migrations")
        print("✓ Dropped django_migrations table")
    except Exception as e:
        print(f"✗ Error dropping table: {e}")

print("\nNow run: python manage.py migrate")
