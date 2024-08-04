from PIL import Image
import os
def compress_image_to_size(input_path, output_path, target_size_kb, format='JPEG'):
    """
    Compress an image to a target file size.

    Parameters:
    - input_path: str, path to the input image.
    - output_path: str, path to save the compressed image.
    - target_size_kb: int, target size in kilobytes.
    - format: str, format of the output image (JPEG, PNG, WEBP), default is JPEG.
    """
    img = Image.open(input_path)
    target_size = target_size_kb * 1024  # Convert KB to bytes

    if format.upper() in ['JPEG', 'WEBP']:
        quality = 95  # Start with high quality

        while True:
            img.save(output_path, format=format, quality=quality, optimize=True)
            output_size = os.path.getsize(output_path)

            if output_size <= target_size or quality <= 10:
                break
            quality -= 5  # Reduce quality for further compression

        print(f"Image saved to {output_path} with size {output_size / 1024:.2f} KB and quality {quality}.")
    
    elif format.upper() == 'PNG':
        # For PNG, reduce image dimensions by 10% each time
        scale = 0.9
        img.save(output_path, format=format, optimize=True)
        output_size = os.path.getsize(output_path)

        while output_size > target_size:
            # Resize image
            new_size = (int(img.width * scale), int(img.height * scale))
            img = img.resize(new_size, Image.LANCZOS)
            img.save(output_path, format=format, optimize=True)
            output_size = os.path.getsize(output_path)

        print(f"Image saved to {output_path} with size {output_size / 1024:.2f} KB and reduced dimensions.")

    else:
        raise ValueError("Unsupported image format: {}".format(format))

root='./素材'
paths=os.listdir(root)
for path in paths:
    ml=os.path.join(root,path)
    ml_to=os.path.join(root,path+'_s')
    if ml.endswith('_s'):
        continue
    if not os.path.exists(ml_to):
        os.mkdir(ml_to)
    for v in os.listdir(ml):
        input_path=os.path.join(ml,v)
        output_path=os.path.join(ml_to,v)
        cat=v.split('.')[-1].upper().replace('JPG','JPEG')
        compress_image_to_size(input_path, output_path, 100, format=cat)

