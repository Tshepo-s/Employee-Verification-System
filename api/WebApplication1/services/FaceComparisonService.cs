using Amazon.Rekognition;
using Amazon.Rekognition.Model;

namespace WebApplication1.services
{
   
        public class FaceComparisonService
        {
            private readonly IAmazonRekognition _rekognition;

            public FaceComparisonService(IAmazonRekognition rekognition)
            {
                _rekognition = rekognition;
            }

            public async Task<(bool IsMatch, float Similarity, object RawResponse)> CompareAsync(string sourceUrl, string targetUrl)
            {
                using var httpClient = new HttpClient();

                var sourceBytes = await httpClient.GetByteArrayAsync(sourceUrl);
                var targetBytes = await httpClient.GetByteArrayAsync(targetUrl);

                var request = new CompareFacesRequest
                {
                    SourceImage = new Image { Bytes = new MemoryStream(sourceBytes) },
                    TargetImage = new Image { Bytes = new MemoryStream(targetBytes) },
                    SimilarityThreshold = 80f
                };

                var response = await _rekognition.CompareFacesAsync(request);

                var match = response.FaceMatches.FirstOrDefault();
                var similarity = match?.Similarity ?? 0f;

                return (similarity >= 80f, similarity, response);
            }
        }
}

