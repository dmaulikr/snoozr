package snoozr.neural;

import java.util.Random;

import snoozr.neural.Points;

public class NeuralNet {
	public static final int DEFAULT_MAX_ITERATIONS = 20000;
	public static final double DEFAULT_MIN_ERROR = 0.005;
	public static final double DEFAULT_LEARNING_RATE = 0.3;
	public static final double DEFAULT_MOMENTUM = 0.1;
	
	private int[] sizes;
	private int outputLayer;
	private Layer[] layers;
	private boolean isTrained;
	
	public int maxIterations;
	public double minError;
	public double learningRate;
	public double momentum;
	
	public NeuralNet(int numInputs, int numOutputs) {
		this(numInputs, null, numOutputs);
	}
	
	public NeuralNet(int numInputs, Layer[] hiddenLayers, int numOutputs) {
		maxIterations = DEFAULT_MAX_ITERATIONS;
		minError = DEFAULT_MIN_ERROR;
		learningRate = DEFAULT_LEARNING_RATE;
		momentum = DEFAULT_MOMENTUM;
		
		outputLayer = 1 + (hiddenLayers != null ? hiddenLayers.length : 1);
		sizes = new int[outputLayer + 1];
		layers = new Layer[outputLayer + 1];
		
		isTrained = false;
		
		sizes[0] = numInputs;
		if (hiddenLayers != null) {
			for (int i = 0; i < hiddenLayers.length; i++)
				sizes[i + 1] = hiddenLayers[i].size();
		}
		else {
			// one hidden layer by default
			sizes[1] = Math.max(3, numInputs / 2);
		}
		
		sizes[outputLayer] = numOutputs;
		
		// allocate layers
		for (int layer = 0; layer <= outputLayer; layer++) {
			int size = sizes[layer];
			
			if (layer == 0) {
				layers[layer] = new Layer(zeros(size), zeros(size), zeros(size));
			}
			else {
				int size2 = size * sizes[layer - 1];
				layers[layer] = new Layer(zeros(size), zeros(size), zeros(size), randos(size), randos(size2), zeros(size2));
			}
		}
	}
	
	public double train(TrainingRecord[] records) {
		if (isTrained)
			return -1;
		
		double error = 1.0;
		
		for (int i = 0; i < maxIterations && error > minError; i++) {
			double sum = 0;
			for (TrainingRecord record : records)
				sum += trainPattern(record);
			
			error = sum / records.length;
		}
		
		return error;
	}
	
	private double trainPattern(TrainingRecord record) {
		// forward propogate
		runInput(record.getInputs());
		
		// back propogate
		calculateDeltas(record.getOutputs());
		adjustWeights();
		
		// mean squared error
		double[] errors = layers[outputLayer].errors;
		double sum = 0;
		for (int i = 0; i < sizes[outputLayer]; i++) {
			sum += errors[i] * errors[i];
		}
		
		return sum / sizes[outputLayer];
	}
	
	public double[] runInput(double[] input) {
		System.arraycopy(input, 0, layers[0].outputs, 0, input.length);
		
		for (int layer = 1; layer <= outputLayer; layer++) {
			for (int node = 0; node < sizes[layer]; node++) {
				int idx = node * sizes[layer - 1];
				double[] weights = layers[layer].weights;
				double sum = layers[layer].biases[node];
				
				for (int k = 0; k < sizes[layer - 1]; k++) {
					sum += weights[idx + k] * input[k];
				}
				
				layers[layer].outputs[node] =  1.0 / (1.0 + Math.exp(-sum));
			}
			
			input = layers[layer].outputs;
		}
		
		return layers[outputLayer].outputs;
	}
	
	private void calculateDeltas(double[] target) {
		for (int layer = outputLayer; layer >= 0; layer--) {
			double[] outputs = layers[layer].outputs;
			
			for (int node = 0; node < sizes[layer]; node++) {
				double output = outputs[node];
				
				double error = 0;
				if (layer == outputLayer) {
					error = target[node] - output;
				}
				else {
					double[] deltas = layers[layer + 1].deltas;
					double[] weights = layers[layer + 1].weights;
					
					for (int k = 0; k < sizes[layer + 1]; k++) {
						error += deltas[k] * weights[node + k * sizes[layer]];
					}
				}
				
				layers[layer].errors[node] = error;
				layers[layer].deltas[node] = error * output * (1 - output);
			}
		}
	}
	
	private void adjustWeights() {
		for (int layer = 1; layer <= outputLayer; layer++) {
			double[] incoming = layers[layer - 1].outputs;
			double[] deltas = layers[layer].deltas;
			double[] changes = layers[layer].changes;
			
			for (int node = 0; node < sizes[layer]; node++) {
				double delta = deltas[node];
				
				for (int k = 0; k < sizes[layer - 1]; k++) {
					int idx = k + node * sizes[layer - 1];
					double change = changes[idx];
					
					change = (learningRate * delta * incoming[k]) + (momentum * change);
					
					layers[layer].changes[idx] = change;
					layers[layer].weights[idx] += change;
				}
				
				layers[layer].biases[node] += learningRate * delta;
			}
		}
	}
	
	private double[] randos(int size) {
		Random rand = new Random();
		
		double[] rands = new double[size];
		
		for (int i = 0; i < size; i++)
			rands[i] = rand.nextDouble();
		
		return rands;
	}
	
	private double[] zeros(int size) {
		return new double[size];
	}
}