# Use a stable Node.js version
FROM node:20-alpine

# Set the working directory
WORKDIR /app

# Copy only package.json and package-lock.json first (to optimize Docker caching)
COPY package*.json ./

# Install dependencies
RUN npm install --only=production

# Copy the rest of the application files
COPY . .

# Expose the application port
EXPOSE 3000

# Set environment variables for production
ENV NODE_ENV=production

# Use a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

# Command to start the application
CMD ["npm", "start"]