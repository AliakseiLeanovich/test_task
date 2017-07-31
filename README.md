Regarding proposed improvements:
1. we used different rubies without pinned rake version so the later one throwed such error
  I've pinned rake and moreover added .ruby-version file to avoid this problem
2. initially I've had more than 200 offenses,
  last version has 30 related to method/block length etc. - hidden by .rubocop.yml
3. moved active support require statement from rspec initialization to csv_exporter.rb
4. moved sftp params to constant before class
5. the reason for that refactoring was in the fact that import retry count was always equal to 1
  in initial version, because break always interrupted 5.times loop on the first iteration;
  I've decided to remove it completely in current version because this variable is always 1 and
  not saved or used anywhere except test checks
6. removed errors param from methods
7. unfortunately, I don't see the way to change this behaviour; I don't know initial use case that
  became the reason to call gsub
8. sorry, couldn't get at this point (I could imagine to replace 'if' with 'case', however I'm not sure
  this was your point)
9. Ok, let's start from the very beginning.
  First idea is that initial code contains too much different logic in one file: download from external
  server, csv reading, transaction building and validation, error handling. It would be better to create
  separate object for each this operations and test them from scratch, however time limit gives us no chance.
  So I changed the code to download files first and import their content after download process would finish.
  Next I moved all the import logic into separate module, updated code to be more readable and
  started with some logical improvements: removed unused variables, moved folders building closer to the place
  it is used, removed loop that works just once, removed variables that duplicate class variables.

  Regarding further improvements: it would be great to separate import from csv, data validation and transaction
  building (using objects not classes or class variables that may share data between different calls), both with writing tests for them from the very beginning. Small improvements in current situation may be next:
  - rename CsvExporter to CsvImporter (data is imported, isn't it?)
  - remove unused validate_only param from import methods (we do not use it anywhere explicitly)
  - remove dtaus from import methods params (we may use the same approach as for @errors variable first,
  however it should be object attribute in fact)

Task
=====

The code presented in the task is running in a cronjob every 1 hour as the following task:

```ruby
namespace :mraba do
  task :import do
    CsvExporter.transfer_and_import
  end
end
```

It is connecting via FTP to the "Mraba" service and importing list of transactions from there. The code have the following issues:

* runs very slow
* when occasionally swallow errors
* tests for the code are unreliable and incomplete
* had for new team members to get around it
* not following coding standards

__Instalation__

```
bundle
```

__Test running__
```
rake
```
