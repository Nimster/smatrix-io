$:.push File.expand_path('lib')
require 'smatrix-io'

module SmatrixIO
  class SmatrixIOTest < MiniTest::Unit::TestCase

    def setup
    end

    def teardown
    end

    def test_from_triplet
      t = a_matrix
      csr = CompressedRep.from_triplet(t)
      raw_compare t, csr

      t = random_triplet_matrix
      csr = CompressedRep.from_triplet(t)
      raw_compare t, csr
    end

    # Compare the compressed and triplet representations
    def raw_compare(triplet, compressed)
      assert_equal triplet.nzValues.size, compressed.nzValues.size
      assert_equal triplet.rowNames, compressed.rowNames
      assert_equal triplet.colNames, compressed.colNames

      triplet.rowIdx.zip(triplet.colIdx, triplet.nzValues).each do |i, j, v|
        assert_equal v, get_value(compressed, i, j)
      end
    end

    def get_value(compressed, i, j)
      l = compressed.byRows ? i : j
      m = compressed.byRows ? j : i
      start = compressed.vecStartPtr[l]
      k = compressed.vecIdx[start..(compressed.vecStartPtr[l + 1] - 1)].index(m)
      k.nil? ? 0.0 : compressed.nzValues[start + k]
    end

    def test_transpose
      t = a_matrix
      csr = CompressedRep.from_triplet(t).transpose
      assert_equal t.nzValues.size, csr.nzValues.size
      assert_equal t.rowNames, csr.colNames
      assert_equal t.colNames, csr.rowNames

      t.rowIdx.zip(t.colIdx, t.nzValues).each do |i, j, v|
        assert_equal v, get_value(csr, j, i)
      end
    end

    # A specified matrix for which we know the exact expected values and
    # representations - to avoid symmetric errors
    def a_matrix
      rowNames = (1..4).collect { |i| "row" + i.to_s }
      colNames = (1..4).collect { |i| "col" + i.to_s }
      TripletRep.new(
        [1,1,2,3,3], 
        [1,3,1,1,3],
        [1.0,1.0,2.0,3.0,2.0], 
        rowNames, colNames)
    end

    def random_triplet_matrix
      seed = rand(1000)
      puts "Seed is #{seed}"
      srand(seed)
      rows = rand(9) + 1
      cols = rand(9) + 1
      nz = rand(rows*cols)
      selections = (0..(rows*cols-1)).to_a.sample(nz)
      rowIdx = selections.collect { |s| s / cols }
      colIdx = selections.collect { |s| s % cols }
      nzValues = selections.collect { |s| (rand * 10)+0.001 }
      rowNames = (1..rows).collect { |i| "row" + i.to_s }
      colNames = (1..cols).collect { |i| "col" + i.to_s }
      TripletRep.new(rowIdx, colIdx, nzValues, rowNames, colNames)
    end
  end
end
