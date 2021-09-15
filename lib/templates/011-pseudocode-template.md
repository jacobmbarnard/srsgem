# Pseudocode

*Used to describe complex code in an "English-y" way so that the concept of a given algorithm is clear. Pseudocode should be easily understood by programmers so that said programmers can transalate the pseudocode into real programming language(s) and thus implement modules of the system.*

<!-- Replace the following placeholders. Delete this line when complete. -->

## Login Process

```javascript
let LoginSys be a class that handles processing user credentials against the identity (ID) provider;

function callback(user) {
    take user to dashboard;
}

LoginSys.process(username, password, callback) {
    process username and password against ID provider;
    if success {
        callback(u);
    } else {
        go to login screen and show error;
    }
}

```