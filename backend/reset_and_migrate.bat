@echo off
echo Stopping any Python processes...
taskkill /F /IM python.exe 2>nul
timeout /t 2 /nobreak >nul

echo Deleting old database...
del /F /Q db.sqlite3 2>nul
del /F /Q db.sqlite3-journal 2>nul

echo Running migrations...
python manage.py migrate

echo.
echo Database reset complete!
echo.
echo Next steps:
echo 1. Create superuser: python manage.py createsuperuser
echo 2. Start server: python manage.py runserver
