# Stage 1: The "Builder" Stage
FROM python:3.10-slim-bullseye AS builder

RUN apt-get update && \
    apt-get install -y build-essential && \
    rm -rf /var/lib/apt/lists/*

# Create a virtual environment to keep dependencies isolated
RUN python -m venv /opt/venv

# Activate the virtual environment for all subsequent commands
ENV PATH="/opt/venv/bin:$PATH"

# Set the working directory for our app
WORKDIR /app

# Upgrade pip and install Gunicorn, a production-ready web server
RUN pip install --upgrade pip && \
    pip install gunicorn

# Copy the requirements file and install the app's dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: The "Final" Image
FROM python:3.10-slim-bullseye

# Create a non-root user and its group for security
RUN adduser --system --group nonroot

# Set the working directory
WORKDIR /home/nonroot/app

# Copy the virtual environment (with all dependencies) from the builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy the application code into the final image
COPY . .

RUN mkdir -p Uploads && chown -R nonroot:nonroot .

# Now, switch to our non-root user
USER nonroot

# Set the PATH to use the Python interpreter and packages from our virtual environment
ENV PATH="/opt/venv/bin:$PATH"

# Set environment variables for the application
ENV PORT=8888
ENV FLASK_DEBUG=0

# Expose the port the app will run on
EXPOSE 8888

# The command to start the app using the Gunicorn server
CMD gunicorn --bind 0.0.0.0:$PORT app:app