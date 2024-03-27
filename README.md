## Mx.Sample_Bot
#### Create your own sample packs for mx.samples on norns

Inspired by multisample kit creation on the 1010 Blackbox, Mx.Sample_Bot is a simple script that helps automate the process of sampling external synths to create multisample packs for [mx.samples](https://llllllll.co/t/mx-samples/41400).

### Overview

Mx.Sample_Bot sends a sequence of midi notes to the selected device while recording the audio input. Segments of the resulting audio buffer corresponding to each note are then saved as individual .wav files to the appropriate folder using the [naming convention required by mx.samples](https://llllllll.co/t/mx-samples/41400/66) (`<midinote>.<dynamic>.<dynamics>.<variation>.<release>.wav`). 

### Requirements

- norns
- mx.samples
- a sound-making device that receives midi

### Documentation
1. Connect your synth 
    - norns midi out -> your synth midi in
    - your synth audio out -> norns audio in 
2. Use E2 and E3 to select your device, adjust settings, and define the sequence of notes to be recorded
    - The script will use "start note", "end note", and "sample every" to determine which notes to include in the sequence.
    - The total length of each sample is equal to "note sustain" + "note release"
    - For dynamics for each note, set "velocity layers" > 1, and then define the minimum and maximum velocity values. 
3. Press K2 to audition the sequence
4. Press K3 to record the sequence
5. Hold K1 and press K2 to listen to the recorded sequence
6. Hold K1 and press K3 to save the recorded sequence as a sample pack in dust/audio/mx.samples/
7. Open a script that utilizes mx.samples. You should find the pack you created listed among the available instruments. 
8. To include multiple variations of each note in your sample pack, repeat steps 1-6 multiple times, changing only the value for "variation", and save the recordings into the same folder each time.  

* Note: The above process should work fine for most scripts that utilize mx.samples as a library (e.g. Plonky, o-o-o, zxcvbn, Spirals). However, in order for your sample pack to appear as an available instrument in the default mx.samples script, you will need to add the name of your pack to the `available_instruments` table in `mx.samples.lua`. You can use an arbitrary number for size. E.g. `{{name="my instrument",size=1},}`

### Download

