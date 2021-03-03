# frozen_string_literal:true

# A Ruby program that plays the game Mastermind. The user can play as either the codemaker or code breaker

# Contains all the display text
module Display
  def display_intro
    puts <<~INTRO
      Welcome to Mastermind, the colours are red, yellow, orange, green, blue and purple.
      After each guess you will be provided with feedback on your guess.
      The first number represents the number of correct colour and position guesses.
      The second number represents the number of correct colour but incorrect position guesses.
    INTRO
  end

  def display_win
    puts 'Congratulations, you have guessed the code!'
    display_code
  end

  def display_code
    puts "The code was #{code[0]}, #{code[1]}, #{code[2]}, #{code[3]}."
  end

  def lost_game
    puts 'Unfortunately you did not guess the code'
    display_code
  end

  def display_invalid_input
    puts 'Invalid input, please try again.'
  end
end

# Contains main game logic which asks the user for their guesses and displays the feedback
class Game
  include Display

  attr_reader :board, :code, :computer

  def initialize
    @board = Board.new
    @code = @board.random_code
    @guesses = @board.guesses
    @computer = Computer.new
  end

  def play
    display_intro
    1.upto(12) do |guess_num|
      guess = player_guess(guess_num)
      break if guess == code

      store_guesses_and_feedback(guess, code)
      board.show_guesses_and_feedback(guess_num)
      return lost_game if guess_num == 12
    end
    display_win
  end

  def player_guess(guess_num)
    puts "Please enter your guess seperated by spaces. This is guess number #{guess_num}:"
    guess = gets.chomp.strip.downcase.split
    return guess if board.valid_input?(guess)

    display_invalid_input
    player_guess(guess_num)
  end

  def store_guesses_and_feedback(guess, code)
    board.guesses << guess
    board.all_feedback << computer.provide_feedback(guess, code)
  end
end

# Contains data for the board
class Board
  attr_accessor :guesses, :all_feedback

  def initialize
    @colours = %w[red yellow orange green blue purple]
    @code = []
    @guesses = []
    @all_feedback = []
  end

  def random_code
    @code = @colours.sample(4)
  end

  def valid_input?(guess)
    guess.uniq.count == 4 && (guess - @colours).empty?
  end

  def show_guesses_and_feedback(guess_num)
    puts 'Your guesses and feedback so far:'
    guess_num.times do |num|
      print "Guess ##{num + 1} #{guesses[num]} "
      p all_feedback[num]
    end
  end
end

# Contains computer player logic which provides feedback
class Computer
  def initialize; end

  def provide_feedback(guess, code)
    [correct_position(guess, code), correct_colour(guess, code) - correct_position(guess, code)]
  end

  def correct_position(guess, code)
    count = 0
    4.times { |num| count += 1 if guess[num] == code[num]}
    count
  end

  def correct_colour(guess, code)
    4 - (guess - code).count
  end
end

game = Game.new
game.play
