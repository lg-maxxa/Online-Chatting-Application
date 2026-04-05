/**
 * NexusChat Backend – Unit & Integration Tests
 *
 * Uses Jest + Supertest.
 * Tests run against an in-memory MongoDB instance via environment variables.
 */

const request = require('supertest');

// Mock mongoose connect so tests don't need a real DB
jest.mock('../config/db', () => jest.fn());

// Mock S3 config so tests don't need AWS credentials
jest.mock('../config/s3', () => ({
  upload: {
    single: () => (_req, _res, next) => next(),
  },
  s3Client: {},
}));

const { app } = require('../server');

describe('Health Check', () => {
  it('GET /health returns 200', async () => {
    const res = await request(app).get('/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('404 Handler', () => {
  it('returns 404 for unknown routes', async () => {
    const res = await request(app).get('/api/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body.message).toBe('Route not found.');
  });
});

describe('Auth Routes – Input Validation', () => {
  it('POST /api/auth/register rejects missing fields', async () => {
    const res = await request(app).post('/api/auth/register').send({});
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });

  it('POST /api/auth/register rejects invalid email', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'testuser',
      email: 'not-an-email',
      password: 'password123',
    });
    expect(res.status).toBe(400);
    expect(res.body.errors.some((e) => e.path === 'email')).toBe(true);
  });

  it('POST /api/auth/register rejects short password', async () => {
    const res = await request(app).post('/api/auth/register').send({
      username: 'testuser',
      email: 'test@example.com',
      password: 'short',
    });
    expect(res.status).toBe(400);
    expect(res.body.errors.some((e) => e.path === 'password')).toBe(true);
  });

  it('POST /api/auth/login rejects missing password', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'test@example.com',
    });
    expect(res.status).toBe(400);
    expect(res.body.errors).toBeDefined();
  });

  it('POST /api/auth/login rejects invalid email format', async () => {
    const res = await request(app).post('/api/auth/login').send({
      email: 'bad-email',
      password: 'password123',
    });
    expect(res.status).toBe(400);
  });
});

describe('Protected Routes – Unauthenticated Access', () => {
  it('GET /api/users/search returns 401 without token', async () => {
    const res = await request(app).get('/api/users/search?q=test');
    expect(res.status).toBe(401);
  });

  it('GET /api/chats returns 401 without token', async () => {
    const res = await request(app).get('/api/chats');
    expect(res.status).toBe(401);
  });

  it('POST /api/chats returns 401 without token', async () => {
    const res = await request(app).post('/api/chats').send({ participantId: 'someId' });
    expect(res.status).toBe(401);
  });

  it('GET /api/messages/someId returns 401 without token', async () => {
    const res = await request(app).get('/api/messages/someId');
    expect(res.status).toBe(401);
  });

  it('POST /api/auth/logout returns 401 without token', async () => {
    const res = await request(app).post('/api/auth/logout');
    expect(res.status).toBe(401);
  });

  it('GET /api/auth/me returns 401 without token', async () => {
    const res = await request(app).get('/api/auth/me');
    expect(res.status).toBe(401);
  });
});
