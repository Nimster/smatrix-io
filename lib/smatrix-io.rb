require "smatrix-io/version"

module SmatrixIO
  # Your code goes here...
  
  class TripletRep

    def initialize(rowIdx, colIdx, nzValues, rowNames = nil, colNames = nil, 
                   nrows = rowNames.size, ncols = colNames.size)
      @rowIdx, @colIdx, @nzValues, @rowNames, @colNames, @nrows, @ncols = \
        rowIdx, colIdx, nzValues, rowNames, colNames
    end

  end

  class CompressedRep

    def initialize(nzValues, vecIdx, vecStartPtr, 
                   rowNames = nil, colNames = nil,
                   nrows = rowNames.size, ncols = colNames.size, byRows = true)
      @nzValues, @vecIdx, @vecStartPtr, @rowNames, @colNames = \
        nzValues, vecIdx, vecStartPtr, rowNames, colNames 
      @nrows, @ncols, @byRows = nrows, ncols, byRows
      
    end

    # Adapted from CSparse's cs_compress() method
    def self.from_triplet(triplet, byRows = true)
      m, n = triplet.nrows, triplet.ncols
      nz = triplet.num_entries
      nrows, ncols = m, n
      nzValues = Array.new(nz)
      vecIdx = Array.new(nz)
      vecStartPtr = Array.new(m + 1)
      byRows = true
      rowNames, colNames = triplet.rowNames, triplet.colNames
      # Get the column counts
      w = triplet.rowIdx.reduce(Array.new(m)) do |w, i|
        w[i] += 1
        w
      end
      CompressedRep.cs_cumsum(vecStartPtr, w)

      0.upto(nz) do |k|
        p = w[triplet.rowIdx[k]]
        w[triplet.rowIdx[k]] += 1
        vecIdx[p] = triplet.colIdx[k]
        nzValues[p] = triplet.nzValues[k]
      end
      CompressedRep.new(nzValues, vecIdx, vecStartPtr, rowNames, 
                        colNames, m, n, byRows)
    end

    # p[0..n] = cumulative sum of c[0..n-1], and then copy p[0..n-1] into c.
    # Adapted from CSparse
    def self.cs_cumsum(p, c)
      nz = 0
      0.upto(p.size - 1) do |i|
        p[i] = nz
        nz += c[i]
        c[i] = p[i]
      end
      p[p.size] = nz
    end

    # Returns a transposed copy of the matrix. If you exchange the row names and
    # column names after the operation, you have effectively swapped CSR with
    # CSC and vice versa
    #
    # Adapted from CSparse
    def transpose()
      m, n = @nrows, @ncols
      w = Array.new(@byRows ? n : m)
      nz = @nzValues.size
      newNzValues = Array.new(nz)
      newVecIdx = Array.new(nz)
      newVecStartPtr = Array.new(w.size + 1)
      # Row counts for CSC, column counts for CSR
      @vecIdx.each do |l|
        w[l] += 1
      end
      CompressedRep.cs_cumsum(newVecStartPtr, w)
      t = byRows ? m : n
      0.upto(t) do |j|
        @vecStartPtr[j].upto(@vecStartPtr[j + 1]) do |p|
          q = w[@vecIdx[p]]
          w[@vecIdx[p]] += 1
          newVecIdx[q] = j
          newNzValues[q] = @nzValues[p]
        end
      end
      CompressedRep.new(newNzValues, newVecIdx, newVecStartPtr, colNames, 
                        rowNames, n, m, byRows)
    end

  end
end
