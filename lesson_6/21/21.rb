# frozen_string_literal: true

MSG = <<HEREDOC
  --------------------------
    Welcome to Twenty-One!
  --------------------------
HEREDOC
CARDS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
SUITS = ["\u2660", "\u2663", "\u2665", "\u2666"].freeze
NUM_OF_DECKS = 1
WINNING_SCORE = 5
BUST_THRESHOLD = 21
DEALER_THRESHOLD = 17
VALID_HIT = %w[h hit].freeze
VALID_STAY = %w[s stay].freeze
VALID_YES_OR_NO = %w[y yes n no].freeze
NUM_OF_SECONDS = 2

def clear_screen
  system 'clear'
end

def initialize_deck
  deck = []
  CARDS.each do |card|
    SUITS.each do |suit|
      deck << "#{card}#{suit}"
    end
  end
  (deck * NUM_OF_DECKS).shuffle
end

def player_hit_or_stay?
  answer = ''
  loop do
    puts 'Would you like to (h)it or (s)tay?'
    answer = gets.chomp.downcase
    break if (VALID_HIT + VALID_STAY).include?(answer)

    puts "Please enter 'h', 's', 'hit' or 'stay'."
  end
  answer
end

def sum_if_ace_equals_11(values)
  sum = 0
  values.each do |value|
    if value == 'A'
      sum += 11
    elsif value.to_i.zero?
      sum += 10
    else
      sum += value.to_i
    end
  end
  sum
end

def total(participants, participant)
  values = participants[participant][:cards].map { |card| card[0...-1] }
  sum = sum_if_ace_equals_11(values)

  values.select { |value| value == 'A' }.count.times do
    sum -= 10 if sum > BUST_THRESHOLD
  end

  sum
end

def deal_card(participants, participant, deck)
  participants[participant][:cards] << deck.shift
end

def first_deal(participants, deck)
  2.times do
    deal_card(participants, :player, deck)
    deal_card(participants, :dealer, deck)
  end
end

def busted?(total)
  total > BUST_THRESHOLD
end

def player_move(participants, deck)
  loop do
    decision = player_hit_or_stay?
    deal_card(participants, :player, deck) if VALID_HIT.include?(decision)
    participants[:player][:total] = total(participants, :player)
    break if VALID_STAY.include?(decision) || busted?(participants[:player][:total])

    clear_screen
    display_cards(participants)
  end
end

def player_turn(participants, deck)
  player_move(participants, deck)
  participants[:dealer][:total] = total(participants, :dealer)

  return unless busted?(participants[:player][:total])

  clear_screen
  display_cards(participants)
  display_result(participants)
end

def dealer_move(participants, deck)
  loop do
    break if participants[:dealer][:total] >= DEALER_THRESHOLD

    deal_card(participants, :dealer, deck)
    participants[:dealer][:total] = total(participants, :dealer)
    clear_screen
    display_cards(participants)
    sleep NUM_OF_SECONDS
  end
end

def dealer_turn(participants, deck)
  clear_screen
  display_cards(participants)
  sleep NUM_OF_SECONDS
  dealer_move(participants, deck)
  display_result(participants)
end

def joinand(array, delimiter = ', ', join_word = 'and')
  case array.size
  when 0 then ''
  when 1 then array.first
  when 2 then array.join(' and ')
  else        "#{array[0...-1].join(delimiter)} #{join_word} #{array.last}"
  end
end

def display_cards(participants)
  if participants[:dealer][:total].nil?
    puts "Dealer has: #{participants[:dealer][:cards].first} and unknown card"
  else
    puts "Dealer has: #{joinand(participants[:dealer][:cards])} for a total of #{participants[:dealer][:total]}"
  end

  puts "You have: #{joinand(participants[:player][:cards])} for a total of #{participants[:player][:total]}"
  puts
end

def calculate_result(participants)
  if busted?(participants[:player][:total])
    :player_busted
  elsif busted?(participants[:dealer][:total])
    :dealer_busted
  elsif participants[:player][:total] > participants[:dealer][:total]
    :player
  elsif participants[:dealer][:total] > participants[:player][:total]
    :dealer
  else
    :tie
  end
end

def display_result(participants)
  case calculate_result(participants)
  when :player_busted then puts 'Player busted. Dealer wins!'
  when :dealer_busted then puts 'Dealer busted. Player wins!'
  when :player        then puts 'Player wins!'
  when :dealer        then puts 'Dealer wins!'
  when :tie           then puts "It's a tie!"
  end
end

def update_score!(participants, score)
  case calculate_result(participants)
  when :player_busted then score[:dealer] += 1
  when :dealer        then score[:dealer] += 1
  when :dealer_busted then score[:player] += 1
  when :player        then score[:player] += 1
  end
end

def display_results(score)
  if score[:dealer] > score[:player]
    puts "Dealer #{score[:dealer]}, Player #{score[:player]}"
  else
    puts "Player #{score[:player]}, Dealer #{score[:dealer]}"
  end

  display_champion(score)
  puts
end

def display_champion(score)
  if score[:dealer] == WINNING_SCORE
    puts 'Dealer is the champion!'
  elsif score[:player] == WINNING_SCORE
    puts 'Player is the champion!'
  end
end

def play_again?
  answer = ''
  loop do
    puts 'Play again? (y/n)'
    answer = gets.chomp.downcase
    break if VALID_YES_OR_NO.include?(answer)
  end

  VALID_YES_OR_NO[0..1].include?(answer)
end

def hit_enter_to_continue
  answer = ''
  loop do
    puts 'Hit Enter to continue.'
    answer = gets
    break if answer == "\n"
  end
  clear_screen
end

clear_screen
puts MSG
# reset to a new match & score to 0
loop do
  new_match = nil
  score = { dealer: 0, player: 0 }

  # initialize full deck(s) & shuffle
  loop do
    deck = initialize_deck

    # deal starts here
    loop do
      deck = initialize_deck if deck.count < (26 * NUM_OF_DECKS)
      participants = { dealer: { cards: [], total: nil }, player: { cards: [], total: 0 } }

      first_deal(participants, deck)
      participants[:player][:total] = total(participants, :player)
      display_cards(participants)
      player_turn(participants, deck)
      participants[:dealer][:total] = total(participants, :dealer)
      dealer_turn(participants, deck) unless busted?(participants[:player][:total])
      update_score!(participants, score)
      display_results(score)

      if score.values.include?(WINNING_SCORE)
        new_match = play_again?
        break
      end

      hit_enter_to_continue
    end

    break if new_match || !new_match
  end

  break unless new_match

  clear_screen
end

puts 'Thank you for playing Twenty-One!'
