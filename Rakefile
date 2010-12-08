desc 'Run specs'
task :spec do
  sh 'spec spec/*_spec.rb --color'
end
task :default => :spec

desc 'Install'
task :install do
  folder = '~/.heroku/plugins/heroku-panda'
  sh "rm -rf #{folder}; mkdir -p #{folder} && cp -R . #{folder}"
end