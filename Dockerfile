# Build stage
FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copy pom.xml and pre-fetch dependencies for Docker cache
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# Copy source code and build jar
COPY src ./src
RUN mvn clean package -DskipTests -B

# Runtime stage
FROM eclipse-temurin:21-jre-jammy
WORKDIR /app

# Non-root user for security
RUN groupadd -r docusphere && useradd -r -g docusphere docusphere
RUN mkdir -p /app/uploads && chown -R docusphere:docusphere /app

COPY --from=build /app/target/*.jar app.jar
RUN chown docusphere:docusphere app.jar

USER docusphere

EXPOSE 8080
ENV PORT=8080

ENTRYPOINT ["sh", "-c", "java -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 -Dserver.port=${PORT} -jar app.jar"]
