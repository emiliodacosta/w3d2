require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class Users
  attr_accessor :name
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM users")
    data.map { |datum| Users.new(datum) }
  end

  def self.find_by_id(id)
    person = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    Users.new(person.first)
  end

  def self.find_by_name(name)
    person = QuestionsDatabase.instance.execute(<<-SQL, name)
      SELECT
        *
      FROM
        users
      WHERE
        name = ?
    SQL
    Users.new(person.first)
  end

  def initialize(options)
    @id = options['id']
    @name = options['name']
  end

  def authored_questions
    Questions.find_by_author_id(@id)
  end

  def authored_replies
    Replies.find_by_user_id(@id)
  end

  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end

  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end

  def average_karma
    all_my_questions = Questions.find_by_author_id(@id)
    likes_on_each_question = all_my_questions.map do |each_question|
      QuestionLikes.num_likes_for_question_id(each_question.id)
    end

    likes_on_each_question.reduce(&:+).to_f / likes_on_each_question.length
  end

  def save
    if @id
      QuestionsDatabase.instance.execute(<<-SQL, @name, @id)
        UPDATE
          users
        SET
          name = ?
        WHERE
          id = ?
      SQL
    else
      QuestionsDatabase.instance.execute(<<-SQL, @name)
        INSERT INTO
          users (name)
        VALUES
          (?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
  end

end

class Questions
  attr_accessor :body, :title, :author_id
  attr_reader :id

  def self.all
    data = QuestionsDatabase.instance.execute("SELECT * FROM questions")
    data.map { |datum| Questions.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    Questions.new(question.first)
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author_id = ?
    SQL
    questions.map { |question| Questions.new(question) }
  end

  def self.most_followed(n)
    QuestionFollow.most_followed_questions(n)
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author_id = options['author_id']
  end

  def author
    Users.find_by_id(@author_id)
  end

  def replies
    Replies.find_by_question_id(@id)
  end

  def followers
    QuestionFollows.followers_for_question_id(@id)
  end

  def likers
    QuestionLikes.likers_for_question_id(@id)
  end

  def num_likes
    QuestionLikes.num_likes_for_question_id(@id)
  end

  def most_liked(n)
    QuestionLikes.most_liked_questions(n)
  end
end

class Replies
  attr_accessor :body, :question_id, :author_id
  attr_reader :id, :parent_id

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    Replies.new(reply.first)
  end

  def self.find_by_user_id(author_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        replies
      WHERE
        author_id = ?
    SQL
    replies.map { |each_reply| Replies.new(each_reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT  *
    FROM replies
    WHERE question_id = ?
    SQL
    replies.map { |each_reply| Replies.new(each_reply) }
  end

  def initialize(options)
    @id = options['id']
    @body = options['body']
    @question_id = options['question_id']
    @author_id = options['author_id']
    @parent_id = options['parent_id']
  end

  def author
    Users.find_by_id(@author_id)
  end

  def question
    Questions.find_by_id(@question_id)
  end

  def parent_reply
    return nil if @parent_reply.nil?
    Replies.find_by_id(@parent_id)
  end

  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL
    replies.map { |each_reply| Replies.new(each_reply) }
  end

end

class QuestionFollows
  attr_accessor :question_id, :author_id
  attr_reader :id
  def self.find_by_id(id)
    follows = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    QuestionFollows.new(follows.first)
  end

  def self.most_followed_questions(n)
    mfquestions = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT *
    FROM question_follows
    JOIN questions ON question_follows.question_id = questions.id
    GROUP BY question_id
    ORDER BY count(question_id) DESC
    LIMIT ?
    SQL
    mfquestions.map { |question| Questions.new(question) }
  end

  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
    SELECT *
    FROM question_follows
    JOIN users ON question_follows.author_id = users.id
    WHERE question_follows.question_id = ?
    SQL
    followers.map { |each_follower| Users.new(each_follower) }
  end

  def self.followed_questions_for_user_id(author_id)
    followed_qs = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT *
    FROM question_follows
    JOIN questions ON question_follows.question_id = questions.id
    WHERE question_follows.author_id = ?
    SQL
    followed_qs.map { |each_question| Questions.new(each_question) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @author_id = options['author_id']
  end
end

class QuestionLikes
    attr_accessor :question_id, :author_id
    attr_reader :id

  def self.find_by_id(id)
    like = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    QuestionLikes.new(like.first)
  end

  def self.likers_for_question_id(question_id)
    liking_users = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        question_likes
      JOIN users ON author_id = users.id
      WHERE
        question_likes.question_id = ?
      SQL
    liking_users.map { |user| Users.new(user) }
  end

  def self.num_likes_for_question_id(question_id)
    num_likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        COUNT(id) as number_of_likes
      FROM
        question_likes
      WHERE
        question_likes.question_id = ?
    SQL
    num_likes.first['number_of_likes']
  end

  def self.liked_questions_for_user_id(author_id)
    questions_user_likes = QuestionsDatabase.instance.execute(<<-SQL, author_id)
    SELECT *
    FROM question_likes
    JOIN questions ON question_id = questions.id
    WHERE question_likes.author_id = ?
    SQL
    questions_user_likes.map { |likedq| Questions.new(likedq) }
  end

  def self.most_liked_questions(n)
    most_liked_qs = QuestionsDatabase.instance.execute(<<-SQL, n)
    SELECT *
    FROM question_likes
    JOIN questions on question_id = questions.id
    GROUP BY question_id
    ORDER BY COUNT(question_likes.id) DESC
    LIMIT ?
    SQL
    most_liked_qs.map { |q| Questions.new(q) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @author_id = options['author_id']
  end
end
