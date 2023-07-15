require "sinatra"
require 'sinatra/reloader' # if ENV['RACK_ENV'] == 'development'
require "sinatra/content_for"
require "slim"
require 'json'
require 'pry'
require_relative 'sudoku_solver'
configure { set :server, :puma }

load 'colors.rb'
# load 'puzzles/puzzle_90.rb'
# PUZZLE_101 = {"12":9,"15":2,"16":3,"17":8,"18":7,"22":1,"24":5,"31":4,"41":3,"46":1,"51":6,"53":4,"57":1,"59":9,"64":7,"69":2,"79":3,"86":7,"88":6,"92":3,"93":2,"94":8,"95":4,"98":5}
PUZZLE_102 = {"13":6,"16":8,"24":2,"31":8,"33":9,"37":3,"38":5,"39":7,"42":7,"47":5,"53":8,"55":9,"57":6,"63":1,"68":4,"71":5,"72":3,"73":4,"77":9,"79":1,"86":1,"94":6,"97":7}
# load 'puzzles/puzzle_42.rb'

# class App < Sinatra::Base
#   register Sinatra::Reloader
begin
  #---------------------------------
  get '/' do
    redirect :board
  end

  #---------------------------------
  get '/board' do
    slim :'vue-board'
  end

  #---------------------------------
  get '/cells' do
    content_type :json

    # initialize with empty board
    # cells = []
    # (1..9).to_a.each do |row|
    #   (1..9).to_a.each do |col|
    #     suspects = color == 0 ? [1,2,3,4,5,6,7,8,9] : [color]
    #     cells << { 'id' => row*10+col, 'color' => color, 'suspects' => suspects }
    #   end
    # end

    # The exporter creates hashes with keys that are symbols. We need the keys to be integers.
    # puzzle = PUZZLE_101.each_with_object({}) { |rec, puzzle| puzzle[rec[0].to_s.to_i] = rec[1] }
    puzzle = PUZZLE_102.each_with_object({}) { |rec, puzzle| puzzle[rec[0].to_s.to_i] = rec[1] }
    # puzzle = PUZZLE_42.each_with_object({}) { |rec, puzzle| puzzle[rec[0].to_s.to_i] = rec[1] }

    # initialize board with puzzle
    cells = []
    (1..9).to_a.each do |row|
      (1..9).to_a.each do |col|
        color = puzzle.fetch(row*10+col, 0)
        suspects = color == 0 ? [1,2,3,4,5,6,7,8,9] : [color]
        cells << { 'id' => row*10+col, 'color' => color, 'suspects' => suspects }
      end
    end

    cells.to_json
  end

  #---------------------------------
  post '/solve' do
    request.body.rewind  # in case someone already read it
    data = JSON.parse request.body.read

    puzzle = data['cells'].each_with_object({}) do |cell, puzzle|
      puzzle[cell['id']] = cell['color'] == 0 ? nil : cell['color']
    end

    vue_cells = []
    SudokuSolver.new.tap do |sudoku|
      sudoku.import_puzzle puzzle

      # puts Benchmark.measure {
        loops = sudoku.run(false)
        puts "total loop count = #{loops}"
      # }

      # sudoku.dump_results
      puts "SUCCESS" if sudoku.success?
      vue_cells = sudoku.to_vue
    end

    vue_cells.to_json
  end

  #---------------------------------
  post '/export' do
    request.body.rewind  # in case someone already read it
    data = JSON.parse request.body.read

    puzzle = data['cells'].each_with_object({}) do |cell, puzzle|
      if cell['color'] != 0
        puzzle[cell['id']] = cell['color']
      end
    end

    # send_file "./files/#{filename}", :filename => filename, :type => 'Application/octet-stream'
    content_type :json
    puzzle.to_json
  end
end
