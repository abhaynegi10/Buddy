# My Flutter Project

... (other project info) ...

## Setup

1.  Clone the repository: `git clone <your-repo-url>`
2.  `cd your_project_directory`
3.  `flutter pub get`

## Configuration - API Key Required!

This project requires a Google Gemini API key to function.

1.  **Locate the example secrets file:** `lib/secrets.dart.example`
2.  **Create your secrets file:** Copy the example file to a new file named `secrets.dart` in the same directory:
    ```bash
    cp lib/secrets.dart.example lib/secrets.dart
    ```
    *(Note: `lib/secrets.dart` is listed in `.gitignore` and will not be committed.)*
3.  **Edit `lib/secrets.dart`:** Open the newly created `lib/secrets.dart` file and replace the placeholder `'YOUR_GEMINI_API_KEY_HERE'` with your actual Gemini API key.
4.  Save the file.

You should now be able to run the app.

## Running the App

```bash
flutter run 
