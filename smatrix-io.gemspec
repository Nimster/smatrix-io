# -*- encoding: utf-8 -*-
require File.expand_path('../lib/smatrix-io/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Nimrod Priell"]
  gem.email         = ["nimrod.priell@gmail.com"]
  gem.description   = %q{Sparse matrix input and output in various formats}
  gem.summary       = %q{CSR, CSC and Triplet sparse matrix format, with row and column names}
  gem.homepage      = ""

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "smatrix-io"
  gem.require_paths = ["lib"]
  gem.version       = Smatrix::Io::VERSION
end
