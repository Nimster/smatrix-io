$:.push File.expand_path('lib')
require 'smatrix-io'

module SmatrixIO
  class SmatrixIOTest < MiniTest::Unit::TestCase

    def setup
    end

    def teardown
    end

    def test_initializers
      t = a_matrix
      csr = CompressedRep.from_triplet(t)
      raw_compare t, csr
    end

    # Compare the compressed and triplet representations
    def raw_compare(triplet, compressed)
      assert_equal triplet.nzValues.size, compressed.nzValues.size
      assert_equal triplet.rowNames, compressed.rowNames
      assert_equal triplet.colNames, compressed.colNames

      triplet.rowIdx.zip(triplet.colIdx, triplet.nzValues).each do |i, j, v|
        l = compressed.byRows ? i : j
        m = compressed.byRows ? j : i
        start = compressed.vecStartPtr[l]
        k = compressed.vecIdx[start..(compressed.vecStartPtr[l + 1] - 1)].index(m)
        refute k.nil?
        assert_equal v, compressed.nzValues[start + k]
      end
    end

    # A specified matrix for which we know the exact expected values and
    # representations - to avoid symmetric errors
    def a_matrix
      rowNames = (1..4).collect { |i| "row" + i.to_s }
      colNames = (1..4).collect { |i| "col" + i.to_s }
      t = TripletRep.new(
        [1,1,2,3,3], 
        [1,3,1,1,3],
        [1.0,1.0,2.0,3.0,2.0], 
        rowNames, colNames)
    end

    def random_triplet_matrix
    end
  end
end
