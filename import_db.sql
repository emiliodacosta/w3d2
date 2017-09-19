DROP TABLE IF EXISTS users;

CREATE TABLE users (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL
);

DROP TABLE IF EXISTS questions;

CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  author_id INTEGER,

  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_follows;

CREATE TABLE question_follows (
  id INTEGER PRIMARY KEY,
  author_id INTEGER,
  question_id INTEGER,

  FOREIGN KEY (author_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

DROP TABLE IF EXISTS replies;

CREATE TABLE replies (
  id INTEGER PRIMARY KEY,
  body TEXT NOT NULL,
  question_id INTEGER NOT NULL,
  author_id INTEGER NOT NULL,
  parent_id INTEGER,


  FOREIGN KEY (question_id) REFERENCES questions(id),
  FOREIGN KEY (parent_id) REFERENCES replies(id),
  FOREIGN KEY (author_id) REFERENCES users(id)
);

DROP TABLE IF EXISTS question_likes;

CREATE TABLE question_likes (
  id INTEGER PRIMARY KEY,
  author_id INTEGER,
  question_id INTEGER,

  FOREIGN KEY (author_id) REFERENCES users(id),
  FOREIGN KEY (question_id) REFERENCES questions(id)
);

INSERT INTO
  users (name)
VALUES
  ('Emilio'),
  ('Kelby'),
  ('AA');

INSERT INTO
  questions (title, body, author_id)
VALUES
  ('Help', 'How do we pass the assessment?', (SELECT id FROM users WHERE name = 'Kelby')),
  ('Urgent', 'Where is the bathroom?', (SELECT id FROM users WHERE name = 'Kelby')),
  ('Curious', 'When should we be sleeping?', (SELECT id FROM users WHERE name = 'Emilio'));

INSERT INTO
  replies (body, question_id, author_id, parent_id)
VALUES
  ('I don''t know', (SELECT id FROM questions WHERE title = 'Help'), (SELECT id FROM users WHERE name = 'AA'), NULL),
  ('Follow your nose', (SELECT id FROM questions WHERE title = 'Urgent'), (SELECT id FROM users WHERE name = 'AA'), NULL),
  ('Just inherit sleep!', (SELECT id FROM questions WHERE title = 'Curious'), (SELECT id FROM users WHERE name = 'AA'), NULL);

INSERT INTO
  replies (body, question_id, author_id, parent_id)
VALUES
  ('Just memorize everything!', (SELECT id FROM questions WHERE title = 'Help'), (SELECT id FROM users WHERE name = 'Kelby'), (SELECT id FROM replies WHERE body = 'I don''t know')),
  ('tf does that mean?', (SELECT id FROM questions WHERE title = 'Curious'), (SELECT id FROM users WHERE name = 'Emilio'), (SELECT id FROM replies WHERE body = 'Just inherit sleep!'));

INSERT INTO
  replies (body, question_id, author_id, parent_id)
VALUES
  ('This is a grandchild to question(1) and reply(1).', (SELECT id FROM questions WHERE title = 'Help'), (SELECT id FROM users WHERE name = 'AA'), (SELECT id FROM replies WHERE body = 'Just memorize everything!'));

INSERT INTO
  question_follows (question_id, author_id)
VALUES
  (2, 1),
  (3, 2);

INSERT INTO
  question_likes (question_id, author_id)
VALUES
  (2, 1);
