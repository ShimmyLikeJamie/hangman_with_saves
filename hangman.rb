class Game
  attr_accessor :current_turn, :guessed_letters, :word_to_guess
  attr_reader :answer

  def initialize game_state
    @answer = game_state[:answer]
    @word_to_guess = game_state[:word_to_guess]
    @current_turn = game_state[:current_turn]
    @guessed_letters = game_state[:guessed_letters]
  end

  def self.loadgame?
    puts "Hello and welcome to hangman!"
    puts "Would you like to start a new game, or load an existing one?"
    loop do
      puts "Select an option"
      puts "1: New Game"
      puts "2: Load Game"
      puts "3: Exit"
      choice = gets.chomp
      case choice
      when "1"
        return false
      when "2"
        return true
      when "3"
        exit
      else
        puts "Invalid option!"
      end
    end
  end

  def self.new_game
    game_state = {}
    game_state[:answer] = select_word.chomp
    game_state[:word_to_guess] = Array.new(game_state[:answer].length, "_")
    game_state[:current_turn] = 0
    game_state[:guessed_letters] = []
    game_state
  end

  def self.loadgame
    saves = get_save_files

    loop do
      saves.each_with_index {|x, i| puts "#{i}: #{x}"}
      print "Select a saved game (0-9): "
      game_user_wants_to_load = gets.chomp.to_i
      if game_user_wants_to_load < 0 || game_user_wants_to_load > 9
        next
      else
        game_to_load = saves[game_user_wants_to_load]
        puts "#{game_to_load}"
        #Now we have the filename, we just need to open it and read in the game_state info
        file = File.open("saves/#{game_to_load}.txt", "r")
        contents = file.read
        game_state_elements = contents.split("~")
        game_state = {}
        game_state[:answer] = game_state_elements[0]
        game_state[:word_to_guess] = game_state_elements[1].split(",")
        game_state[:current_turn] = game_state_elements[2].to_i
        if game_state_elements[3] == nil
          game_state[:guessed_letters] = []
        else
          game_state[:guessed_letters] = game_state_elements[3].split(",")
        end
        return game_state
      end
    end

  end
end

def select_word
  words = File.open($dictionary_file_name).readlines
  word_selected = false
  while word_selected == false
    word = words[rand(0..words.length)]
    word_selected = true unless word.length < 5 || word.length > 12
  end
  word
end

def guess? game
  puts "You have #{$max_guesses - game.current_turn} turns left!"
  if $max_guesses - game.current_turn == 0
    $loser = true
    return
  end
  loop do
    puts "Please select an option:"
    puts "1: Guess a letter"
    puts "2: Save game"
    user_input = gets.chomp
    case user_input
    when "1"
      return true #Should go to guessing stage
    when "2" 
      return false #Should save game
    else
      puts "Invalid choice"
    end
  end
end

def guess_letter game
  loop do
    if $max_guesses - game.current_turn == 0
      $loser = true
      return
    end
    prompt_player game
    guessed_letter = gets.chomp.downcase
    player_guess game, guessed_letter
    if player_win? game
      $winner = true
    end
    game.current_turn += 1
    return
  end
end

def prompt_player game 
  puts "Your word so far is: #{game.word_to_guess}"
  puts "Your guessed letters so far are: #{game.guessed_letters}"
  puts "Please guess a letter: "
end

def player_guess game, guessed_letter
  if game.guessed_letters.to_s.include? guessed_letter
    puts "You have already guessed that letter!"
  elsif game.answer.include? guessed_letter
    puts "Letter found!"
    i = 0
    while i < game.answer.length
      if game.answer[i] == guessed_letter
       game.word_to_guess[i] = guessed_letter
      end
      i += 1
    end
    game.guessed_letters.push(guessed_letter)
  elsif guessed_letter.length > 1 || !(guessed_letter.instance_of? String)
    puts "Invalid input!"
  else
    puts "Letter not found!"
    game.guessed_letters.push(guessed_letter)
  end
end

def player_win? game
  game.answer == game.word_to_guess.to_s  
end

def win_or_lose?
  $winner || $loser
end

def show_win_or_loss
  if $winner
    puts "You win!"
    $winner = false
  elsif $loser
    puts "You lose!"
    $loser = false
  end
end

def setup_game game_state
  game = Game.new(game_state)
  puts "Your word to guess is #{game.word_to_guess}"
  game
end

def get_save_files
  puts "Pick a save to load:"
  saves = Dir["./saves/*"].collect {|x| x.gsub("./saves/", "")}
  saves = saves.collect {|x| x.gsub(".txt", "")}
  saves
end

def save_game game
  puts "Name your save file!"
  save_name = gets.chomp.downcase
  save_file = File.open("saves/#{save_name}", "w")
  word_to_guess_save_format = ""
  game.word_to_guess.each do |letter|
    word_to_guess_save_format += letter
    word_to_guess_save_format += ","
  end
  word_to_guess_save_format[-1] = ""
  guessed_letters_save_format = ""
  if game.guessed_letters == !nil
    game.guessed_letters.each do |letter|
      guessed_letters_save_format += letter
      guessed_letters_save_format += ","
    end
    guessed_letters_save_format[-1] = ""
  end
  save_file.puts "#{game.answer}~#{word_to_guess_save_format}~#{game.current_turn.to_s}~#{guessed_letters_save_format}"
end

$max_guesses = 13 #Change this to change the number of turns
$dictionary_file_name = "list_of_words.txt" #You can change this file in order to change your list of words
$winner = false
$loser = false

loop do
  if Game.loadgame?
    game_state = Game.loadgame
  else
    game_state = Game.new_game
  end
  game = setup_game game_state
  until win_or_lose?
      if guess? game
        guess_letter game
      else
        save_game game
      end
  end
  show_win_or_loss
end