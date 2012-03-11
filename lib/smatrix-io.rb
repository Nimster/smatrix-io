# Module for holding and transforming sparse matrix representations in Ruby,
# based on CSparse. The goal is to be able to read and write matrixes in both
# triplet representations and compressed representations, using whichever is
# more comfortable for the required operations and 
#
# See more on http://educated-guess.com/2011/02/22/sparse-matrices/
# Follow me on twitter: @nimrodpriell
#
# Author::    Nimrod Priell (@nimrodpriell)
# Copyright:: Copyright (c) 2012 Nimrod Priell
# License::   Distributes under the same terms as Ruby
#

require "smatrix-io/version"

module SmatrixIO

  # Class for operations on triplet representation
  class TripletRep
    attr_reader :rowIdx, :colIdx, :nzValues
    attr_reader :rowNames, :colNames, :nrows, :ncols

    # Directly create a triplet representation from the constituent triplets
    # (provided as the 3 arrays +rowIdx+, +colIdx+ and +nzValues+) and
    # optionally names for the rows and columns. If you don't want names, you
    # have to provide the length of the rows and columns:
    #
    #     TripletRep.new([],[],[],nil,nil,4,3) # 4 rows, 3 columns matrix
    #     
    #     TripletRep.new([],[],[],%w[r1 r2], %w[c1 c2]) # 2 rows, 2 columns 
    #     
    # Note the internal representation is 0-based, so the first row has index 0
    def initialize(rowIdx, colIdx, nzValues, rowNames = nil, colNames = nil, 
                   nrows = rowNames.size, ncols = colNames.size)
      @rowIdx, @colIdx, @nzValues, @rowNames, @colNames, @nrows, @ncols = \
        rowIdx, colIdx, nzValues, rowNames, colNames, nrows, ncols
    end

  end

  # Class for operations on compressed representations. You can create this from
  # a triplet representation using 
  #
  #    CompressedRep.from_triplet(triplet)
  class CompressedRep

    attr_reader :nzValues, :vecIdx, :vecStartPtr
    attr_reader :rowNames, :colNames, :nrows, :ncols
    attr_reader :byRows

    # Directly create a compressed vector representation from the constituent
    # datum.
    def initialize(nzValues, vecIdx, vecStartPtr, 
                   rowNames = nil, colNames = nil,
                   nrows = rowNames.size, ncols = colNames.size, byRows = true)
      @nzValues, @vecIdx, @vecStartPtr, @rowNames, @colNames = \
        nzValues, vecIdx, vecStartPtr, rowNames, colNames 
      @nrows, @ncols, @byRows = nrows, ncols, byRows
      
    end

    # Adapted from CSparse's cs_compress() method, this creates a *CSR* matrix.
    # To change to CSC, call 'to_csc'
    def self.from_triplet(triplet)
      m, n = triplet.nrows, triplet.ncols
      nz = triplet.nzValues.size
      nrows, ncols = m, n
      nzValues = Array.new(nz)
      vecIdx = Array.new(nz)
      vecStartPtr = Array.new(m + 1, 0)
      byRows = true
      rowNames, colNames = triplet.rowNames, triplet.colNames
      # Get the column counts
      w = triplet.rowIdx.reduce(Array.new(m, 0)) do |w, i|
        w[i] += 1
        w
      end
      CompressedRep.cs_cumsum(vecStartPtr, w)

      0.upto(nz - 1) do |k|
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
      0.upto(c.size - 1) do |i|
        p[i] = nz
        nz += c[i]
        c[i] = p[i]
      end
      p[-1] = nz
    end

    # Returns a transposed copy of the matrix. If you exchange the row names and
    # column names after the operation, you have effectively swapped CSR with
    # CSC and vice versa. This also has the side effect of sorting the vectors
    #
    # Adapted from CSparse
    def transpose()
      m, n = @nrows, @ncols
      w = Array.new(@byRows ? n : m, 0)
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
      0.upto(t - 1) do |j|
        @vecStartPtr[j].upto(@vecStartPtr[j + 1] - 1) do |p|
          q = w[@vecIdx[p]]
          w[@vecIdx[p]] += 1
          newVecIdx[q] = j
          newNzValues[q] = @nzValues[p]
        end
      end
      # TODO: This is undone by transpose_dim, so perhaps do the above in
      # transpose_internal, and transpose_dim only if you need a real transpose
      # and not just a CSR->CSC switch
      CompressedRep.new(newNzValues, newVecIdx, newVecStartPtr, colNames, 
                        rowNames, n, m, @byRows)
    end

    # Returns the sparse matrix in the requested representation (CSR is the
    # default)
    def to_direction(byRows = true)
      if byRows == @byRows
        self
      else
        transpose.transpose_dim
      end
    end

    # Returns the sparse matrix in CSC representation
    def to_csc
      to_direction(false)
    end

    # Returns the sparse matrix in CSR representation
    alias_method :to_csr, :to_direction

    # Internal method for switching the way we look at the matrix without
    # changing the values. This is safe after a transpose and will turn a CSC
    # matrix to a CSR one
    def transpose_dim
      # Switch the column names and row names
      temp = @colNames
      tempn = @ncols
      @colNames = @rowNames
      @ncols = @nrows
      @rowNames = temp
      @nrows = tempn
      @byRows = (not @byRows)
      self
    end

    def pick_rows(*rows)
      orig = self.to_csr # Then we can avoid running over the whole matrix
      newRowNames = rows.collect { |r| @rowNames[r] }
      newNzValues = rows.collect do |r| 
        # unfortunately using ranges straightforward doesn't work because
        # a[0..-1] is the whole array.
        @nzValues.values_at(*(@vecStartPtr[r]..(@vecStartPtr[r + 1] - 1)).to_a)
      end.flatten
      newVecIdx = rows.collect do |r| 
        @vecIdx.values_at(*(@vecStartPtr[r]..(@vecStartPtr[r + 1] - 1)).to_a)
      end.flatten
      newVecStartPtr = Array.new(rows.size + 1)
      CompressedRep.cs_cumsum(newVecStartPtr, 
        rows.collect { |r| @vecStartPtr[r + 1] - @vecStartPtr[r] })
      orig.rowNames = newRowNames
      orig.nrows = rows.size
      orig.nzValues = newNzValues
      orig.vecIdx = newVecIdx
      orig.vecStartPtr = newVecStartPtr
      orig
    end

    protected

    attr_writer :nzValues, :vecIdx, :vecStartPtr
    attr_writer :rowNames, :colNames, :nrows, :ncols
    attr_writer :byRows

  end
end
