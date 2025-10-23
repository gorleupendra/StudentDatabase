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
RUN mvn clean package -DskipTests

# Download webapp-runner.jar (latest stable version for reproducibility)
RUN wget -O webapp-runner.jar https://repo1.maven.org/maven2/com/github/jsimone/webapp-runner/9.0.72.0/webapp-runner-9.0.72.0.jar

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

# Copy the built .war file from the 'builder' stage
COPY --from=builder /app/target/*.war app.war

# Render exposes port 10000 by default; make it configurable if needed
EXPOSE 10000

# Health check (optional, assumes your app has a /health endpoint; adjust as needed)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:10000/health || exit 1

# This command starts the server using the copied JAR and WAR files
CMD ["java", "-jar", "webapp-runner.jar", "--port", "10000", "app.war"]