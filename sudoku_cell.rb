class SudokuCell
  attr_accessor :color, :possible_colors
  attr_reader :id, :h, :v, :b

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
    if self.possible_colors.include?(color) 
      self.possible_colors -= [color]
      return true
    end
    false
  end

  #---------------------------------
  def promote_naked_single
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
  
  #---------------------------------
  def to_vue
    { 'id' => self.id, 'color' => self.color || 0, 'suspects' => self.possible_colors }
  end
end

