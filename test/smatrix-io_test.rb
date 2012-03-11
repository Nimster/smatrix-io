#require 'minitest/autorun'
class LookupTest < MiniTest::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_initializers
    assert_equal 0, CarKind.count
    assert_equal 0, CarColor.count
    bimba = Car.new(:name => "Bimba", :kind => "Compact", :color => "Yellow")
    assert_equal "Yellow", bimba.color
    assert_equal "Compact", bimba.kind
    assert_equal "Bimba", bimba.name
    assert_equal 1, CarKind.count
    assert_equal 1, CarColor.count
    ferrari = Car.new(:kind => "Sports", :color => "Yellow")
    assert_equal "Yellow", ferrari.color
    assert_equal "Sports", ferrari.kind
    refute(ferrari == bimba)
    assert_equal bimba.color_id, ferrari.color_id
    refute_equal bimba.kind_id, ferrari.kind_id
    assert_equal 2, CarKind.count
    assert_equal 1, CarColor.count
    f16 = Plane.new(:name => "F-16", :kind => "Fighter Jet")
    assert_equal "Fighter Jet", f16.kind
    assert_equal 1, PlaneKind.count
  end

end
