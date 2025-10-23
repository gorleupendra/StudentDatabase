# ---------------------------
# Stage 1: Build .war file
# ---------------------------
# Use a Maven/Java 17 image to build the project
FROM maven:3.9-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy the POM file first for better caching of dependencies
COPY pom.xml .

# Copy the source code
COPY src ./src

# Build the WAR file, skipping tests for deployment
# The -U flag forces an update of dependencies, clearing bad cache
RUN mvn clean package -U -DskipTests

# CHANGED: Use the correct 'com.heroku' groupId and a valid version
RUN mvn dependency:get -Dartifact=com.heroku:webapp-runner:9.0.97.0 -Ddest=webapp-runner.jar

# ---------------------------
# Stage 2: Run the application
# ---------------------------
# Use a lightweight Java 17 image for the runtime
FROM eclipse-temurin:17-jre-jammy

# Create a non-root user for security
RUN addgroup --system appgroup && adduser --system appuser --ingroup appgroup

# Set working directory
WORKDIR /app

# Switch to non-root user
USER appuser

# Copy webapp-runner.jar from the builder stage
COPY --from=builder /app/webapp-runner.jar .

# Copy the built .war file
COPY --from=builder /app/target/admin-portal.war app.war

# Render exposes port 10000 by default
EXPOSE 10000

# Health check (optional, adjust as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:10000/health || exit 1

# This command starts the server
CMD ["java", "-jar", "webapp-runner.jar", "--port", "10000", "app.war"]