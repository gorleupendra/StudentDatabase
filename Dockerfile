# ---------------------------
# Stage 1: Build .war file
# ---------------------------
# CHANGED: Use a Maven/Java 20 image to build the project
FROM maven:3.9.6-eclipse-temurin-20 AS builder

# Set working directory
WORKDIR /app

# Copy the POM file first for better caching of dependencies
COPY pom.xml .

# Copy the source code
COPY src ./src

# Build the WAR file, skipping tests for deployment
# The -U flag forces an update of dependencies
RUN mvn clean package -U -DskipTests

# REMOVED: webapp-runner.jar is no longer needed
# We will use a full Tomcat server instead.

# ---------------------------
# Stage 2: Run the application
# ---------------------------
# CHANGED: Use the official Tomcat 10.1 image.
# We use the jdk21 tag because it's the latest Long-Term Support (LTS)
# version and is required to run code compiled with Java 20.
FROM tomcat:10.1-jdk20-temurin

# Remove the default Tomcat webapps (manager, examples, etc.)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy the .war file from the 'builder' stage into Tomcat's webapps directory
# It is renamed to 'ROOT.war' so it deploys to the root URL
# (e.g., https://your-app.onrender.com/ instead of /admin-portal)
COPY --from=builder /app/target/admin-portal.war /usr/local/tomcat/webapps/ROOT.war

# CHANGED: Expose port 8080
# This is Tomcat's default port.
# Render will automatically map its external port (like 10000) to this.
EXPOSE 8080

# CHANGED: Updated health check to use port 8080
# This just checks if the Tomcat server is responding on the root page.
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# REMOVED: The custom CMD is no longer needed.
# The 'tomcat:10.1' base image already includes the correct
# command (CMD ["catalina.sh", "run"]) to start the server.
