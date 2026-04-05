// Jest setup – set required environment variables before tests run
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test_jwt_secret_for_testing_only';
process.env.JWT_EXPIRES_IN = '1d';
process.env.MONGO_URI = 'mongodb://localhost:27017/nexuschat_test';
process.env.AWS_ACCESS_KEY_ID = 'test_key';
process.env.AWS_SECRET_ACCESS_KEY = 'test_secret';
process.env.AWS_REGION = 'us-east-1';
process.env.AWS_S3_BUCKET_NAME = 'test-bucket';
