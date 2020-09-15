# Github Util

github util is a ruby script list for dealing with github issue.

### check_story_point_in_the_title
- check story point in your issue title
- story point format is like `[1]`

## Usage

### check_story_point_in_the_title
```
1. Bundle install

2. cp config.yml.template config.yml

3 edit config.yml with below 
  - GITHUB_ACCESS_TOKEN: your github access token
  - REPOSITORY: your repository
  - PROJECT_NUMBER: your project number (https://github.com/hoge/huga/projects/1)
  - COLUMN_NAMES: column name list that you want to check
  - MESSAGE: message when no story point was found

4. bundle exec ruby check_story_point_in_the_title.rb
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
[MIT](https://choosealicense.com/licenses/mit/)
