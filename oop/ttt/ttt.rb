require 'yaml'

MESSAGES = YAML.load_file("messages.yml")

module Printable
  def clear
    system 'clear'
  end

  def prompt(message)
    puts "=> #{MESSAGES[message]}"
  end

  def joinor(list, delimiter=', ', word='or')
    case list.length
    when 0 then ''
    when 1 then list.join
    when 2 then list.join(" #{word} ")
    else        list[0..-2].join(delimiter) + "#{delimiter}#{word} #{list[-1]}"
    end
  end

  def continue
    prompt :continue
    gets
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonal
  CENTER_SQUARE = 5

  attr_reader :squares

  def initialize
    @squares = {}
    reset
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def []=(num, marker)
    squares[num].marker = marker
  end

  def full?
    unmarked_keys.empty?
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def someone_won?
    !!winning_marker
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def immediate_threat(marker)
    WINNING_LINES.each do |line|
      markers = squares.values_at(*line).map(&:marker)
      if markers.count(marker) == 2
        line.each { |key| return key if squares[key].unmarked? }
      end
    end
    nil
  end

  def center_square_empty?
    squares[CENTER_SQUARE].unmarked?
  end

  private

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def to_s
    marker
  end
end

class Player
  include Printable

  ALPHABET = ('a'..'n').to_a + ('p'..'z').to_a

  attr_reader :name, :marker, :score

  def initialize
    @name = retrieve_name
    @marker = retrieve_marker
    @score = 0
  end

  def increment_score
    self.score += 1
  end

  def reset_score
    self.score = 0
  end

  private

  attr_writer :name, :score

  def retrieve_name
    name = ''
    loop do
      prompt :player_name
      name = gets.chomp
      break if name =~ /[\w]/
      prompt :invalid_input
    end
    name
  end

  def retrieve_marker
    puts ''
    marker = ''
    loop do
      prompt :player_marker
      marker = gets.chomp
      break if ALPHABET.include?(marker.downcase)
      prompt :invalid_input
    end
    marker
  end
end

class Computer < Player
  attr_accessor :name

  def initialize(marker)
    @name = nil
    @marker = marker
  end
end

class TTTGame
  include Printable

  COMPUTER_MARKER = 'O'
  VALID_ANSWERS = {
    '1' => { difficulty: 'Easy', opponent: 'WALL-E' },
    '2' => { difficulty: 'Medium', opponent: 'R2D2' },
    '3' => { difficulty: 'Advanced', opponent: 'Optimus Prime' }
  }

  def play_match
    loop do
      reset_score
      choose_who_goes_first
      choose_difficulty_and_opponent
      main_game
      display_champion
      break unless play_again?
    end
    display_goodbye_message
  end

  private

  attr_accessor :current_marker, :difficulty, :first_to_move
  attr_reader :board, :human, :computer

  def initialize
    display_welcome_message
    @board = Board.new
    @human = Player.new
    @computer = Computer.new(COMPUTER_MARKER)
    @first_to_move = nil
    @current_marker = nil
  end

  def display_welcome_message
    clear
    prompt :welcome_message
    puts ""
  end

  def ask_who_goes_first
    puts ''
    answer = ''
    loop do
      puts format(MESSAGES[:who_goes_first], name: human.name.to_s)
      answer = gets.chomp
      break if VALID_ANSWERS.keys.include?(answer)
      prompt :invalid_number
    end
    answer
  end

  def choose_who_goes_first
    answer = ask_who_goes_first

    marker =
      case answer
      when '1' then human.marker
      when '2' then COMPUTER_MARKER
      when '3' then [human.marker, COMPUTER_MARKER].sample
      end

    self.first_to_move = marker
    self.current_marker = marker
  end

  def choose_difficulty_and_opponent
    puts ''
    answer = ''
    loop do
      prompt :difficulty
      answer = gets.chomp
      break if VALID_ANSWERS.keys.include?(answer)
      prompt :invalid_number
    end
    self.difficulty = VALID_ANSWERS[answer][:difficulty]
    computer.name = VALID_ANSWERS[answer][:opponent]
  end

  def reset_score
    human.reset_score
    computer.reset_score
  end

  def display_board
    puts ""
    board.draw
    puts ""
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def clear_screen_and_display_board
    clear
    display_score
    display_board
  end

  def human_moves
    square = ''
    loop do
      puts "=> Choose a square: (#{joinor(board.unmarked_keys)})"
      square = gets.chomp.to_i
      break if board.unmarked_keys.include?(square)
      prompt :invalid_square
    end
    board[square] = human.marker
  end

  def computer_moves
    difficulty
    square =
      case difficulty
      when 'Easy' then easy_difficulty_move
      when 'Medium' then medium_difficulty_move
      when 'Advanced' then advanced_difficulty_move
      end

    board[square] = computer.marker
  end

  def advanced_difficulty_move
    if board.center_square_empty?
      Board::CENTER_SQUARE
    elsif board.immediate_threat(COMPUTER_MARKER)
      board.immediate_threat(COMPUTER_MARKER)
    else
      medium_difficulty_move
    end
  end

  def medium_difficulty_move
    board.immediate_threat(human.marker) || easy_difficulty_move
  end

  def easy_difficulty_move
    board.unmarked_keys.sample
  end

  def current_player_moves
    if human_turn?
      human_moves
      self.current_marker = COMPUTER_MARKER
    else
      computer_moves
      self.current_marker = human.marker
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def display_result
    clear_screen_and_display_board
    case board.winning_marker
    when human.marker then    puts "=> #{human.name} won!"
    when computer.marker then puts "=> #{computer.name} won!"
    else                      prompt :tie
    end
    puts ''
    continue unless game_over?
  end

  def update_score
    case board.winning_marker
    when human.marker then human.increment_score
    when computer.marker then computer.increment_score
    end
  end

  def game_over?
    human.score == 5 || computer.score == 5
  end

  def display_score
    puts "=> #{human.name} (#{human.marker}): #{human.score}, " \
         "#{computer.name} (#{computer.marker}): #{computer.score}"
    puts ""
  end

  def display_champion
    champion = (human.score == 5 ? human.name : computer.name.to_s)
    puts "=> #{champion} is the champion!"
  end

  def play_again?
    answer = ''
    loop do
      prompt :play_again?
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      prompt :invalid_yes_no
    end
    answer == 'y'
  end

  def reset
    board.reset
    self.current_marker = first_to_move
    clear
  end

  def display_goodbye_message
    prompt :goodbye_message
    puts ""
  end

  def main_game
    loop do
      reset
      display_score
      display_board
      player_move
      update_score
      display_result
      break if game_over?
    end
  end
end

game = TTTGame.new
game.play_match
