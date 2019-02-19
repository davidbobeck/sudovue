require "./sudoku_cell"
# require "./time_utilities"

class SudokuSolver
  attr_accessor :cells, :colors, :h, :v, :b

  CELL_BEING_OBSERVED = 48
  
  #---------------------------------
  def initialize
    @h = []
    @v = []
    @b = []
    @cells = {}
    @colors = (1..9).to_a
    make_board
  end

  #---------------------------------
  def make_board
    # horizontal cell zones
    self.h[1] = (11..19).to_a
    self.h[2] = (21..29).to_a
    self.h[3] = (31..39).to_a
    self.h[4] = (41..49).to_a
    self.h[5] = (51..59).to_a
    self.h[6] = (61..69).to_a
    self.h[7] = (71..79).to_a
    self.h[8] = (81..89).to_a
    self.h[9] = (91..99).to_a

    # vertical cell zones
    self.v[1] = (1..9).map { |n| (n*10) + 1 }
    self.v[2] = (1..9).map { |n| (n*10) + 2 }
    self.v[3] = (1..9).map { |n| (n*10) + 3 }
    self.v[4] = (1..9).map { |n| (n*10) + 4 }
    self.v[5] = (1..9).map { |n| (n*10) + 5 }
    self.v[6] = (1..9).map { |n| (n*10) + 6 }
    self.v[7] = (1..9).map { |n| (n*10) + 7 }
    self.v[8] = (1..9).map { |n| (n*10) + 8 }
    self.v[9] = (1..9).map { |n| (n*10) + 9 }

    # box cell zones
    self.b[1] = (11..13).to_a + (21..23).to_a + (31..33).to_a
    self.b[2] = (14..16).to_a + (24..26).to_a + (34..36).to_a
    self.b[3] = (17..19).to_a + (27..29).to_a + (37..39).to_a
    self.b[4] = (41..43).to_a + (51..53).to_a + (61..63).to_a
    self.b[5] = (44..46).to_a + (54..56).to_a + (64..66).to_a
    self.b[6] = (47..49).to_a + (57..59).to_a + (67..69).to_a
    self.b[7] = (71..73).to_a + (81..83).to_a + (91..93).to_a
    self.b[8] = (74..76).to_a + (84..86).to_a + (94..96).to_a
    self.b[9] = (77..79).to_a + (87..89).to_a + (97..99).to_a

    # the cells
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        self.cells[id] = SudokuCell.new(id)
      end
    end
  end

  #---------------------------------
  def clear_board
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        self.cells[id].clear_cell
      end
    end
  end

  #---------------------------------
  def to_vue
    self.cells.map { |id, sc| sc.to_vue }
  end

  #---------------------------------
  def import_puzzle(puzzle = {})
    puzzle.each do |id, color|
      self.cells[id].set_color(color)
    end
  end

  #---------------------------------
  def success?
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        return false if self.cells[id].color.nil?
      end
    end
    true
  end

  #---------------------------------
  def run(with_dump = false)
    run_loop = true
    loop_count = 0

    while true
      break if run_loop == false
      run_loop = false
      loop_count += 1
      puts "loop count = #{loop_count}"
      
      # fuse breaker
      break if loop_count > 100
      
      #####################
      #  STRATEGY
      #####################

      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
        
        run_loop |= strategy_of_eliminating_knowns(cell, self.h[cell.h])
        run_loop |= strategy_of_eliminating_knowns(cell, self.v[cell.v])
        run_loop |= strategy_of_eliminating_knowns(cell, self.b[cell.b])

        # if eight of the colors have already been used,
        # then it must be the nineth
        # run_loop |= cell.promote_naked_single
        result = cell.promote_naked_single
        if result
          puts "STRATEGY 0: (NAKED SINGLE) Set #{cell.id} to #{cell.color}"
          run_loop = true
        end
    end

      #####################
      #  STRATEGY
      #####################
      
      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
        
        run_loop |= strategy_of_knowing_where_it_cant_go(cell, self.h[cell.h])
        run_loop |= strategy_of_knowing_where_it_cant_go(cell, self.v[cell.v])
        run_loop |= strategy_of_knowing_where_it_cant_go(cell, self.b[cell.b])
      end
      
      #####################
      #  STRATEGY
      #####################

      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
          
        run_loop |= strategy_of_hidden_single(cell, self.h[cell.h])
        run_loop |= strategy_of_hidden_single(cell, self.v[cell.v])
        run_loop |= strategy_of_hidden_single(cell, self.b[cell.b])
      end

      #####################
      #  STRATEGY
      #####################

      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
        
        run_loop |= strategy_of_binary_colors(cell, self.h[cell.h])
        run_loop |= strategy_of_binary_colors(cell, self.v[cell.v])
        run_loop |= strategy_of_binary_colors(cell, self.b[cell.b])
      end
      
      run_loop = false if success?
      dump_results if with_dump
    end

    return loop_count
  end

  #---------------------------------
  def strategy_of_eliminating_knowns(cell, zone_ids)
    peer_ids = zone_ids - [cell.id]
    run_loop = false

    # loop thru all colors
    self.colors.each do |color_to_test|
      peer_ids.each do |id_to_test|
        target = self.cells[id_to_test]
        if target.color == color_to_test
          #debugging code
          # if cell.id == CELL_BEING_OBSERVED
            # puts "STRATEGY 1: remove #{target.color} from #{cell.possible_colors}"
          # end

          # run_loop |= cell.reject_color(target.color)
          possible_colors = cell.possible_colors
          result = cell.reject_color(target.color)
          if result
            puts "STRATEGY 1: remove #{target.color} from #{possible_colors}"
            run_loop = true
          end
        end
      end
    end

    run_loop
  end

  #---------------------------------
  def strategy_of_hidden_single(cell, zone_ids)
    # zone_ids -= [cell.id]
    run_loop = false

    # optimization: remove the cells that have already been identified
    open_ids = []
    known_colors = []

    zone_ids.each do |zone_id|
      zone_cell = self.cells[zone_id]
      open_ids << zone_id if zone_cell.color.nil?
      known_colors << zone_cell.color unless zone_cell.color.nil?
    end.compact

    # get a list of all colors remaining in the zone 
    open_possible_colors = get_zone_possible_colors(open_ids)
    
    # determine the qty of each color
    color_counts = open_possible_colors.group_by { |color| color }.map { |color, group| [color, group.size] }.to_h

    # find the colors that only have a count of 1
    hidden_singles = color_counts.select { |color, count| count == 1 }.map { |color, count| color }

    hidden_singles.each do |hidden_single|
      next if known_colors.include?(hidden_single)
      if cell.possible_colors.include?(hidden_single)
        # run_loop |= cell.set_color(hidden_single)
        again = cell.set_color(hidden_single)
        if again
          # puts "Setting cell #{buddy_id} to color #{hidden_single}"
          # debugging code
          # puts cell.id
          # binding.pry
          # if cell.id == CELL_BEING_OBSERVED
            puts "STRATEGY 3: (HIDDEN SINGLE) Setting cell #{cell.id} to color #{hidden_single}"
          # end
          # binding.pry
          run_loop = true
          break
        end
      end
    end
    
    # puts "Found hidden singles:  #{color_counts}" if run_loop 
    run_loop
  end

  #---------------------------------
  def strategy_of_knowing_where_it_cant_go(cell, zone_ids)
    peer_ids = zone_ids - [cell.id]

    peer_possible_colors = get_zone_possible_colors(peer_ids).uniq

    # now test our results
    xor = (peer_possible_colors + cell.possible_colors) - (peer_possible_colors & cell.possible_colors)
    unique_cell_colors = xor & cell.possible_colors
    # puts "unique_cell_colors = #{unique_cell_colors}" if cell.id == 76

    if unique_cell_colors.count == 1
      # return cell.set_color(unique_cell_colors.first)
      unique_color = unique_cell_colors.first
      result = cell.set_color(unique_color)
      if result
        #debugging code
        # if cell.id == CELL_BEING_OBSERVED
          puts "STRATEGY 2: Setting cell #{cell.id} to color #{unique_color}"
        # end
      end
      return result
    end

    false
  end

  #---------------------------------
  # If two colors only exist in the same two cells, then all
  # other possible colors can be cleared from those two cells.
  def strategy_of_binary_colors(cell, zone_ids)
    peer_ids = zone_ids - [cell.id]
    run_loop = false
    
    peer_ids.each do |buddy_id|
      buddy = self.cells[buddy_id]
      binary_colors = cell.possible_colors & buddy.possible_colors

      if binary_colors.count == 2
        # determine if these colors are unique to the zone
        remainder_peer_ids = peer_ids - [buddy_id]
        remainder_possible_colors = get_zone_possible_colors(remainder_peer_ids).uniq

        if (binary_colors & remainder_possible_colors).count == 0

          # the binary colors are unique?
          if cell.possible_colors != binary_colors || buddy.possible_colors != binary_colors
            # #debugging code
            # if cell.id == CELL_BEING_OBSERVED
            #   puts "STRATEGY 4: changing #{cell.possible_colors} to #{binary_colors}"
            # end

            cell.possible_colors = binary_colors

            # #debugging code
            # if buddy.id == CELL_BEING_OBSERVED
            #   puts "STRATEGY 4: changing #{buddy.possible_colors} to #{binary_colors}"
            # end

            buddy.possible_colors = binary_colors
            run_loop = true
          end
        end
      end
    end
    
    run_loop
  end
  
  #---------------------------------
  def get_zone_possible_colors(zone_ids)
    zone_possible_colors = zone_ids.each_with_object([]) do |zone_id, remaining_colors|
      # puts "zone_id = #{zone_id}, possible_colors = #{self.cells[zone_id].possible_colors}" if cell.id == 76
      remaining_colors << self.cells[zone_id].possible_colors
      # remaining_colors
    end.flatten
    # puts "zone_possible_colors = #{zone_possible_colors}" if cell.id == 76
    zone_possible_colors
  end

  #---------------------------------
  def dump_results
    self.cells.each_key do |id|
      puts self.cells[id].inspect
    end
  end
end
