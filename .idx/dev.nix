{ pkgs, ... }: {
  # The current standard stable channel for IDX configurations
  channel = "stable-24.05"; 

  packages = [
    pkgs.flutter
    pkgs.jdk17   # Required for Android Gradle builds
    pkgs.unzip
  ];
  
  env = {};
  
  idx = {
    extensions = [
      "dart-code.flutter"
      "dart-code.dart-code"
    ];
    
    previews = {
      enable = true;
      previews = {
        android = {
          # This 'manager' tag is the magic word. It forces the cloud server 
          # to download the Android SDK and set ANDROID_HOME automatically.
          command = ["flutter" "run" "--machine" "-d" "android" "-d" "localhost:5555"];
          manager = "flutter";
        };
      };
    };
  };
}