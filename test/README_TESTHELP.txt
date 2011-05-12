
Setting up the testing environment.

Use the mysql client to create mx_test and set permissions. 

  'create database mx_test'
  'GRANT ALL PRIVILEGES ON mx_test.* TO 'mx'@'localhost' IDENTIFIED BY 'my-mx-password' 

Clone the structure of the database to the database.

  rake clone_structure_to_test


