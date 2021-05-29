

### 🍱오늘 뭐먹지?
##### 🧨본프로젝트는 Android,IOS 어플리케이션으로 Inha university에서 진행되었습니다
##### 📆 2020.09.20~ 2020.11.15

---
### 🚀개발 목표 

- User의 편의성을 고려한 Data 입력
- UI/UX 개선
- 추천 알고리즘 사용
- Rest API 
- Flutter 사용
---
### 📱 레시피 추천 앱 개발

-  로그인 기능 

-  레시피 검색 기능 

-  식재료 기반 레시피 추천 

-  식재료 유통기한을 통해 알림기능 

-  유저들의 새로운 레시피 추가기능 

-  음성인식 기능(식재료 추가, 레시피 검색)
---
### Dir 구조 
```
C:.
├─android          ### flutter code를 Android 앱에 맞게 변환
│  ├─app
│  │  └─src
│  │      ├─debug
│  │      ├─main
│  │      │  ├─kotlin
│  │      │  │  └─co
│  │      │  │      └─dotslab
│  │      │  │          └─recipe_app
│  │      │  └─res
│  │      │      ├─drawable
│  │      │      ├─mipmap-hdpi
│  │      │      ├─mipmap-mdpi
│  │      │      ├─mipmap-xhdpi
│  │      │      ├─mipmap-xxhdpi
│  │      │      ├─mipmap-xxxhdpi
│  │      │      └─values
│  │      └─profile
│  └─gradle
│      └─wrapper
├─ios              ### flutter code를 ios 앱에 맞게 변환
│  ├─Flutter
│  ├─Runner
│  │  ├─Assets.xcassets
│  │  │  ├─AppIcon.appiconset
│  │  │  └─LaunchImage.imageset
│  │  └─Base.lproj
│  ├─Runner.xcodeproj
│  │  ├─project.xcworkspace
│  │  │  └─xcshareddata
│  │  └─xcshareddata
│  │      └─xcschemes
│  └─Runner.xcworkspace
│      └─xcshareddata
├─lib                     ### data folder
└─test                    ### simulation folder

```

---
#### 🛠 개발환경 

 `Android Studio , flutter, dart, mongoDB`
---
### [이미지]

- 로그인

<img src = "https://user-images.githubusercontent.com/65913073/118404517-37b36300-b6ae-11eb-8c8d-927445725b82.png" width ="200" height="400"> <img src = "https://user-images.githubusercontent.com/65913073/101260827-eeadc900-3775-11eb-8103-bdc381790f06.png" width ="200" height="400">

- 메인페이지

<img src = "https://user-images.githubusercontent.com/65913073/101260828-f2d9e680-3775-11eb-94c2-9d31e8c9400c.png" width ="200" height="400"> <img src = "https://user-images.githubusercontent.com/65913073/101260836-ff5e3f00-3775-11eb-93ff-d46b10b445dd.png" width ="200" height="400">
- 레시피 추천 

<img src = "https://user-images.githubusercontent.com/65913073/101260842-06854d00-3776-11eb-89b8-6cefdecd9bd8.png" width ="200" height="400"> <img src = "https://user-images.githubusercontent.com/65913073/101260844-0a18d400-3776-11eb-8141-49cda1354d8b.png" width ="200" height="400">

- 로그인 정보 

<img src = "https://user-images.githubusercontent.com/65913073/101260851-1ac94a00-3776-11eb-972c-0e4639574055.png" width ="200" height="400"> <img src = "https://user-images.githubusercontent.com/65913073/101260846-0f761e80-3776-11eb-9212-8cb05cf54259.png" width ="200" height="400">

- 레시피 검색/음성인식 

<img src = "https://user-images.githubusercontent.com/65913073/101260849-156bff80-3776-11eb-9363-7383c914ec3d.png" width ="200" height="400">
