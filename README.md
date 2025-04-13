# 2006-SCSD-C2

**Table of Content**

- [Set Up](#set-up)
  - [Frontend](#frontend)
  - [Backend](#backend)
- [Deliverables](#deliverables)
  - [SRS](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/SCSD%20Group%202%20SRS%20Software%20Requirement%20Specification.pdf)
  - [Class Diagram](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Class%20Diagram.drawio.png)
  - [Dialog Map](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/System%20Architecture.drawio.png)
  - [Use Case Diagram](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Use%20Case%20Diagram.png)
  - [Boundary Control Diagram](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/boundarycontrol%20class.drawio.png)
  - [Video](https://github.com/softwarelab3/2006-SCSD-C2/blob/main/Deliverables/Lab%205/Bussin%20Busses%20Video%20Demostration.mp4)
- [External APIs](#external-apis)
- [Contributors](#contributors)

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

## Tech Stack

**Frontend:**

- Flutter
- Dart

**Backend:**

- NodeJS
- ExpressJS

**Database:**

- Supabase

## Deliverables
1. SRS
2. Class Diagram
3. Dialog Map
4. Use Case Diagram
5. Boundary Control Diagram
6. Video

## External APIs

1. **HERE API**
   - HERE Platform (https://www.here.com/platform)
2. **Traffic Data API**
   - LTA Traffic Images (https://data.gov.sg/datasets?query=lta+traffic+images&page=1&resultId=d_6cdb6b405b25aaaacbaf7689bcc6fae0#tag/default/GET/transport/traffic-images)


### Contributors

| Name                 | Github Username                               | Role       |
| --------------       | --------------------------------------------- | ---------- |
| Lim Li Ping Joey     | [jyorien](https://github.com/jyorien)         | Full-Stack |
| Roger Kwek Zong Heng | [NooB0v0](https://github.com/NooB0v0)         | Full-Stack |
| Matz Chan            | [adamchan7](https://github.com/adamchan7)     | Frontend   |
| Wan Li Xin Yuan      | [WLXinYuan](https://github.com/WLXinYuan)     | Frontend   |
| Cheah Wei Jun        | [WeijunCheah](https://github.com/WeijunCheah) | Frontend   |
| Ong Hong Xun         | [HXong](https://github.com/HXong)             | Backend    |