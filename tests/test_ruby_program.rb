# Класс для демонстрации
class Calculator
  def initialize(value)
    @value = value
  end

  def add(n)
    @value += n
    return @value
  end

  def describe
    if @value > 100
      return "big"
    elsif @value > 10
      return "medium"
    else
      return "small"
    end
  end
end

calc = Calculator.new(50)
calc.add(60)
result = calc.describe
puts "Result: #{result}"

# Цикл
i = 0
while i < 3
  puts "Iteration #{i}"
  i += 1
end

# Массив и хеш
arr = [1, 2, 3]
hash = { "a" => 1, "b" => 2 }

# Строки со спецсимволами
msg = "Line 1\nLine 2\tTabbed"
raw = 'No \n escape here'