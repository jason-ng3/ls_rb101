# frozen_string_literal: true

require 'yaml'

MESSAGES = YAML.load_file('ttt_messages.yml')
INITIAL_MARKER = ' '
PLAYER_MARKER = 'X'
COMPUTER_MARKER = 'O'
WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] +
                [[1, 4, 7], [2, 5, 8], [3, 6, 9]] +
                [[1, 5, 9], [3, 5, 7]]
WINNING_SCORE = 5
CENTER_SQUARE = 5

def prompt(message)
  puts "=> #{MESSAGES[message]}"
end

def who_goes_first?
  answer = ''
  valid_answers = %w[1 2 3]
  prompt :who_goes_first

  loop do
    answer = gets.chomp
    break if valid_answers.include?(answer)

    prompt :enter_valid_option
  end

  answer
end

def first_player
  case who_goes_first?
  when '1' then first_player = 'Player'
  when '2' then first_player = 'Computer'
  when '3' then first_player = %w[Player Computer].sample
  end

  first_player
end

def retrieve_difficulty
  answer = ''
  valid_answers = %w[1 2 3]
  prompt :difficulty

  loop do
    answer = gets.chomp
    break if valid_answers.include?(answer)

    prompt :enter_valid_option
  end

  answer
end

# rubocop:disable Metrics/MethodLength, Metrics/AbcSize
def display_board(board)
  system 'clear'
  puts "You're a #{PLAYER_MARKER}. Computer is #{COMPUTER_MARKER}."
  puts ''
  puts '     |     |'
  puts "  #{board[1]}  |  #{board[2]}  |  #{board[3]}"
  puts '     |     |'
  puts '-----|-----|-----'
  puts '     |     |'
  puts "  #{board[4]}  |  #{board[5]}  |  #{board[6]}"
  puts '     |     |'
  puts '-----|-----|-----'
  puts '     |     |'
  puts "  #{board[7]}  |  #{board[8]}  |  #{board[9]}"
  puts '     |     |'
  puts ''
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize

def initialize_board
  new_board = {}
  (1..9).each { |num| new_board[num] = INITIAL_MARKER }
  new_board
end

def empty_squares(board)
  board.keys.select { |num| board[num] == INITIAL_MARKER }
end

def joinor(array, delimiter = ', ', join_word = 'or')
  case array.size
  when 0 then ''
  when 1 then array.first
  when 2 then array.join(" #{join_word} ")
  else        "#{array.join(delimiter)[0..-3]} #{join_word} #{array.last}"
  end
end

def player_places_piece!(board)
  square = ''

  loop do
    puts format(MESSAGES[:choose_square],
                empty_squares: joinor(empty_squares(board)).to_s)

    square = gets.chomp.to_i
    break if empty_squares(board).include?(square)

    prompt :invalid_choice
  end

  board[square] = PLAYER_MARKER
end

def find_at_risk_square(line, board, marker)
  if board.values_at(*line).count(marker) == 2
    board.select { |k, v| line.include?(k) && v == INITIAL_MARKER }.keys.first
  else
    nil
  end
end

def find_defensive_square(board)
  defensive_square = nil

  WINNING_LINES.each do |line|
    defensive_square = find_at_risk_square(line, board, PLAYER_MARKER)
    break if defensive_square
  end

  defensive_square
end

def find_offensive_square(board)
  offensive_square = nil

  WINNING_LINES.each do |line|
    offensive_square = find_at_risk_square(line, board, COMPUTER_MARKER)
    break if offensive_square
  end

  offensive_square
end

def intermediate_level_square(board)
  find_defensive_square(board) || empty_squares(board).sample
end

def advanced_level_square(board)
  if find_offensive_square(board)
    find_offensive_square(board)
  elsif find_defensive_square(board)
    find_defensive_square(board)
  elsif board[CENTER_SQUARE] == INITIAL_MARKER
    CENTER_SQUARE
  else
    empty_squares(board).sample
  end
end

def computer_places_piece!(board, difficulty)
  case difficulty
  when '1' then square = empty_squares(board).sample
  when '2' then square = intermediate_level_square(board)
  when '3' then square = advanced_level_square(board)
  end

  board[square] = COMPUTER_MARKER
end

def place_piece!(board, current_player, difficulty)
  if current_player == 'Player'
    player_places_piece!(board)
  elsif current_player == 'Computer'
    computer_places_piece!(board, difficulty)
  end
end

def alternate_player(current_player)
  current_player == 'Player' ? 'Computer' : 'Player'
end

def board_full?(board)
  empty_squares(board).empty?
end

def someone_won?(board)
  !!detect_winner(board)
end

def detect_winner(board)
  WINNING_LINES.each do |line|
    return 'Player' if board.values_at(*line).count(PLAYER_MARKER) == 3
    return 'Computer' if board.values_at(*line).count(COMPUTER_MARKER) == 3
  end
  nil
end

def display_result(board)
  if someone_won?(board)
    puts format(MESSAGES[:win], winner: detect_winner(board).to_s)
  else
    prompt :tie
  end
end

def update_score(board, score)
  if detect_winner(board) == 'Player'
    score[:Player] += 1
  elsif detect_winner(board) == 'Computer'
    score[:Computer] += 1
  end
end

def display_score(score)
  puts format(MESSAGES[:score],
              player_score: score[:Player].to_s,
              computer_score: score[:Computer].to_s)
end

def display_champion(score)
  if score[:Player] == WINNING_SCORE
    prompt :player_champion
  elsif score[:Computer] == WINNING_SCORE
    prompt :computer_champion
  end
end

def play_again?
  valid_answers = %w[y yes n no]
  answer = ''

  loop do
    prompt :play_again
    answer = gets.chomp.downcase
    break if valid_answers.include?(answer)
  end
  valid_answers[0..1].include?(answer)
end

# Program starts here
system 'clear'
puts format(MESSAGES[:welcome], winning_score: WINNING_SCORE.to_s)

loop do
  score = { Player: 0, Computer: 0 }
  current_player = first_player
  difficulty = retrieve_difficulty

  loop do
    board = initialize_board

    loop do
      display_board(board)
      place_piece!(board, current_player, difficulty)
      current_player = alternate_player(current_player)
      break if someone_won?(board) || board_full?(board)
    end

    display_board(board)
    display_result(board)
    update_score(board, score)
    display_score(score)
    display_champion(score)
    prompt :continue
    gets
    break if score.values.include?(WINNING_SCORE)
  end

  break unless play_again?

  system 'clear'
end

prompt :thank_you
