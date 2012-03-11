# Smatrix::Io

Rudimentary sparse matrix library for Ruby, mostly meant for reading matrixes
from a sparse matrix file, writing it to a file, and perhaps doing some basic
transformations on the matrix on the way, such as selecting certain rows or
columns.

See [My blog post about sparse matrices][1]

[1][http://educated-guess.com/2011/02/22/sparse-matrices/]

## Installation

Add this line to your application's Gemfile:

    gem 'smatrix-io'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smatrix-io

## Usage

Right now it's not very useful except for looking into the code, as you cannot
read or write from any file format so you have to construct the matrices
yourself. However, you can still move from various representations to others and
operate on the matrix while keeping it sparse throughout, so you maintain
efficiency and low memory requirements:

      rowNames = (1..4).collect { |i| "row" + i.to_s }
      colNames = (1..4).collect { |i| "col" + i.to_s }
      triplets = TripletRep.new(
        [0,0,1,2,2], 
        [0,2,0,0,2],
        [1.0,1.0,2.0,3.0,2.0], 
        rowNames, colNames)
      csr = CompressedRep.from_triplet(orig)
      csc = csr.to_csc
      csc = csc.pick_cols(1, 0, 1) # create a new matrix with second column of
                                   # of the prior matrix, then the first column,
                                   # then the second column again.
      csc = csc.pick_rows(2, 3, 0) # third, fourth, then first row. This will 
                                   # automatically change to CSR format.
      csc = csc.transpose

If you hold on for a little longer or write your own input-output formats
(please contribute!) this could actually start being useful.

## Tests

You can run `rake test`. They're not much but they work. In fact the hard part
of the code is all ported from [CSparse][2] so it is definitely solid.

[2][http://www.cise.ufl.edu/research/sparse/CSparse/]

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
