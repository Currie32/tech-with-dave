# Use an official Python runtime as the base image
FROM python:3.11-slim

# Set the working directory in the container
WORKDIR /app

# Expose port 8080 for running the website
EXPOSE 8080

# Copy the required files
COPY mkdocs.yml requirements.txt ./
COPY docs docs

# Create a virtual environment and activate it
RUN python -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Build the MkDocs site (replace 'docs' with your documentation folder)
RUN mkdocs build

# Start MkDocs serve using the built documentation
CMD ["mkdocs", "serve", "--dev-addr=0.0.0.0:8080"]
