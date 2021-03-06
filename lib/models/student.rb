 class Student

  attr_reader :id


  ATTRIBUTES = {
    :id=>"INTEGER PRIMARY KEY AUTOINCREMENT", 
    :name=>"TEXT", 
    :twitter=>"TEXT", 
    :linkedin=>"TEXT", 
    :facebook=>"TEXT", 
    :website=>"TEXT",
    :student_index=>"TEXT",
    :quote=>"TEXT",
    :bio=>"TEXT",
    :work=>"TEXT",
    :education=>"TEXT",
    :profile_image=>"TEXT",
    :bg_image=>"TEXT",
    :github=>"TEXT",
    :index_image=>"TEXT",
    :excerpt=>"TEXT",
    :tagline=>"TEXT",
    :favorites => "TEXT",
    :favorite_cities => "TEXT",
    :blogs => "TEXT",
    :coder_wall => "TEXT",
    :code_school => "TEXT",
    :treehouse => "TEXT"
  }


  def self.keys_minus_id
    ATTRIBUTES.keys.reject {|k| k == :id}
  end
  
  attr_accessor *self.keys_minus_id

  @@students = []
  @@db=SQLite3::Database.new('students.db')

  def initialize(hash=nil)
    if !hash.nil?
      @name = hash[:name]
      @image_link = hash[:image]
      @twitter = hash[:twitter]
      @linkedin = hash[:linkedin]
      @github = hash[:github]
      @facebook = hash[:facebook]
      @website = hash[:website]
      @quote = hash[:quote]
      @bio = hash[:bio]
      @work = hash[:work]
    end
    if @@students.count == 0
      @id = 1
    else
      @id = @@students.max_by { |s| s.id }.id + 1
    end
    @@students << self
    @saved = false
  end

  def self.reset_all
    @@students.clear
  end

  def self.all
    @@students
  end

  def self.generate_finders
    ATTRIBUTES.keys.each do |attribute|
      define_singleton_method("find_by_#{attribute}".to_sym) do |arg|
        @@students.select { |s| s.send(attribute) == arg }
      end
    end
  end
  Student.generate_finders

  def self.find(id)
    @@students.select { |s| s.id == id }.first
  end

  def self.delete(id)
    @@students.reject! { |s| s.id == id}
  end

  def self.columns_for_sql
    keys_minus_id.join(", ")
  end

  def self.question_marks_insert
    (["?"]* keys_minus_id.length).join(",")
  end

  def values_for_insert
    get_accessors.join(", ")
  end
  
  

  def self.question_marks
    (["?"]*Student.attribute_keys.length).join(",")
  end

  def save
    if @saved==true
      self.update
    else 
      self.insert
    end
  end

  def unsaved
    @saved=false
  end

  def insert
    sql = "INSERT INTO #{self.class.table_name}(#{self.class.columns_for_sql}) VALUES (#{self.class.question_marks_insert});"
    @@db.execute(sql, get_accessors)
    @saved=true
    # 
  end

  def delete
    delete_from_db
    @@students.delete(self)
  end

  def delete_from_db
    sql="DELETE FROM #{self.class.table_name} WHERE id=?"
    @@db.execute(sql, [self.id])
  end

  def update
    unsaved
    insert = "UPDATE #{self.class.table_name} SET #{attributes_for_update} WHERE id = '#{self.id}';"
    @@db.execute(insert)
    @saved=true
  end

  def attributes_without_id
    create_attribute_hash.reject{|key|key==:id}
  end

  def attributes_for_update
    attributes_without_id.collect do |key, value|
      "#{key}='#{value}'"
    end.join(", ")
  end


  def create_attribute_hash
    attribute_hash = Hash[self.class.keys_minus_id.zip self.get_accessors]
  end

  def self.attributes_for_db
    keys_minus_id
  end

  def self.table_name
    "#{self.to_s.downcase}s"
  end

  def self.attributes
    attribute_keys
  end

  def self.attribute_keys
    ATTRIBUTES.keys
  end

  def get_accessors
    self.class.keys_minus_id.collect do |key|
        self.send(key)
    end
  end

  def self.columns_for_create
    ATTRIBUTES.collect do |key, value|
      "#{key} #{value}"
    end.join(", ")   

  end

  def self.load(instance_id)
    @@students.each do |student|
      return student if student.id==instance_id
    end
  end

  def self.create_table
    reset="DROP TABLE #{self.table_name}"
    @@db.execute(reset)
    table="CREATE TABLE IF NOT EXISTS #{self.table_name} (#{self.columns_for_create});" 
    @@db.execute(table)
  end
  self.create_table 

  def self.reset_db
    @@db.execute("DELETE FROM #{table_name};")
  end

end