async function detectFace(videoId) {
  const video = document.getElementById(videoId);
  if (!video) return false;

  // Use face-api.js or TensorFlow.js face detection here
  // Example with face-api.js:
  // const detection = await faceapi.detectSingleFace(video);
  // return detection != null;

  // For demo, return true (replace with actual detection)
  return true;
}

// Expose it globally
window.detectFace = detectFace;
