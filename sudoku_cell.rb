class SudokuCell
  attr_accessor :id, :h, :v, :b, :color, :possible_colors

  #---------------------------------
  def initialize(id, color = nil)
    @id = id
    @h = (id / 10.0).to_i
    @v = id - (@h * 10)
    @b = (((@v-1) / 3.0).to_i) + ((((@h-1) / 3.0).to_i) * 3) + 1 
    @color = color
    @possible_colors = (1..9).to_a
    @possible_colors = [color] unless color.nil?
  end

  #---------------------------------
  def clear_cell
    self.color = nil
    self.possible_colors = (1..9).to_a
  end

  #---------------------------------
  def reject_color(color)
    self.possible_colors -= [color]
  end

  #---------------------------------
  def promote_remaining_color
    if self.possible_colors.count == 1
      winning_color = self.possible_colors.first
      if self.color != winning_color
        return set_color(winning_color)
      end
    end
    false
  end

  #---------------------------------
  def set_color(color)
    return false if self.color == color
    self.color = color
    self.possible_colors = [color] unless color.nil?
    true
  end
end

