# ---------------------------
# Stage 1: Build .war file
# ---------------------------
# Use a Maven/Java 17 image to build the project
FROM maven:3.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY . .
RUN mvn clean package -DskipTests

# ---------------------------
# Stage 2: Run the application
# ---------------------------
# Use a lightweight Java 17 image for the runtime1
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Copy the webapp-runner.jar that you manually added to your project
COPY webapp-runner.jar .

# Copy the built .war file from the 'builder' stage
COPY --from=builder /app/target/*.war app.war

# Render exposes port 10000 by default
EXPOSE 10000

# This command starts the server using the copied JAR and WAR files
CMD ["java", "-jar", "webapp-runner.jar", "--port", "10000", "app.war"]