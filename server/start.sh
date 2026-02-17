#!/bin/bash

echo "========================================"
echo "  TimeSetor Server - Starting..."
echo "========================================"
echo ""

cd "$(dirname "$0")"

if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to create virtual environment"
        echo "Please make sure Python 3.8+ is installed"
        exit 1
    fi
    echo "Virtual environment created successfully."
    echo ""
fi

echo "Activating virtual environment..."
source venv/bin/activate

echo ""
echo "Checking dependencies..."
pip install -r requirements.txt --quiet

echo ""
echo "========================================"
echo "  Starting TimeSetor Server..."
echo "========================================"
echo ""
echo "Server will be available at:"
echo "  - Local: http://localhost:5000"
echo "  - Network: http://YOUR_IP:5000"
echo ""
echo "Press Ctrl+C to stop the server"
echo "========================================"
echo ""

python main.py