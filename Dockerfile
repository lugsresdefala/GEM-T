# Use a base image suitable for the application
FROM python:3.8-slim

# Set the working directory
WORKDIR /app

# Install necessary dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the application code
COPY . .

# Define the entry point for the application
CMD ["python", "app.py"]
