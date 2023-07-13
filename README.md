# cocoapods-linkline

    A plug-in that can customize component dependencies, static libraries/dynamic libraries

## Installation

    $ gem install cocoapods-linkline

## Usage

* Build the component and all child inherit dependencies with dynamic framework 
    ```
    pod 'xxx', :linkages => :dynamic 
    ```
    
* Build the component itself with a dynamic framework

     ```
    pod 'xxx', :linkage => :dynamic 
    ```

* Build the component and all child inherit dependencies with static framework 
    ```
    pod 'xxx', :linkages => :static 
    ```
    
* Build the component itself with a static framework
     ```
    pod 'xxx', :linkage => :static 
    ```