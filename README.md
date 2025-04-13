# 2006-SCSD-C2

## Set Up
Required: Android Studio, Flutter SDK, NodeJS, Supabase keys, HERE API key <br>
Flutter SDK: <br>
On Mac, download using Homebrew with `brew install --cask flutter` <br>
On Windows, download here: https://docs.flutter.dev/get-started/install

Android Studio: <br>
Download here: https://developer.android.com/studio

NodeJS: <br>
On Mac, download using Homebrew with `brew install node` <br>
On Windows download here: https://nodejs.org/en/download

### Frontend
Open /frontend in Android Studio
- run `dart pub get` in terminal to fetch dependencies
- press green start button to run on Android emulator

### Backend
- `cd backend`
- run `npm i`
- clone .env.empty into a file called `.env` and fill in API key details (HERE API: https://www.here.com/platform)
- run `npm start` to start the backend
- run `npm run start:scheduler` to run the fetch and analyse of traffic images (every 3 minutes).


## Deliverables
- SRS: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/SCSD%20Group%202%20SRS%20Software%20Requirement%20Specification.pdf <br>
- Class Diagram: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Class%20Diagram.drawio.png <br>
- Dialog Map: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Dialog%20Map.drawio.png <br>
- System Architecture: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/System%20Architecture.drawio.png <br>
- Use Case Diagram: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Use%20Case%20Diagram.png <br>
- Boundary Control Diagram: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/boundarycontrol%20class.drawio.png <br>
- Video: https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Bussin%20Busses%20Video%20Demostration.mp4
